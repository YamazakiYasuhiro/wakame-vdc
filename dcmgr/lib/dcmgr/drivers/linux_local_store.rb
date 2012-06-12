# -*- coding: utf-8 -*-

module Dcmgr
  module Drivers
    class LinuxLocalStore < LocalStore
      include Dcmgr::Logger
      include Dcmgr::Helpers::CliHelper
      
      def deploy_image(inst,ctx)
        # setup vm data folder
        inst_data_dir = ctx.inst_data_dir
        FileUtils.mkdir(inst_data_dir) unless File.exists?(inst_data_dir)
        img_src_uri = inst[:image][:backup_object][:uri]
        vmimg_basename = inst[:image][:backup_object][:uuid]

        logger.debug("Deploying image file: #{inst[:uuid]}: #{ctx.os_devpath}")

        if Dcmgr.conf.local_store.enable_image_caching
          FileUtils.mkdir_p(vmimg_cache_dir) unless File.exists?(vmimg_cache_dir)
          download_to_local_cache(img_src_uri, vmimg_basename, inst[:image][:backup_object][:checksum])
        else
          paralell_curl(img_src_uri, vmimg_cache_path(vmimg_basename))
        end
        
        logger.debug("copying #{vmimg_cache_path(vmimg_basename)} to #{ctx.os_devpath}")

        case inst[:image][:file_format]
        when "raw"
          # use the file command to detect if the image file is gzip commpressed.
          if  `/usr/bin/file #{vmimg_cache_path(vmimg_basename)}` =~ /: gzip compressed data,/
            sh("zcat %s | cp --sparse=always /dev/stdin %s",[vmimg_cache_path(vmimg_basename), ctx.os_devpath])
          else
            sh("cp -p --sparse=always %s %s",[vmimg_cache_path(vmimg_basename), ctx.os_devpath])
          end
        end

      ensure
        unless Dcmgr.conf.local_store.enable_image_caching
          File.unlink(vmimg_cache_path(vmimg_basename)) rescue nil
        end
      end

      def upload_image(inst, ctx, bo, evcb)
        snapshot_stg = Dcmgr::Drivers::BackupStorage.snapshot_storage(bo[:backup_storage])
        
        bkup_basename = "#{inst[:uuid]}.tmp"
        take_snapshot_for_backup()
        sh("cp -p --sparse=always %s /dev/stdout | gzip -f > %s", [ctx.os_devpath, File.expand_path(bkup_basename, download_tmp_dir)])
        alloc_size = File.size(File.expand_path(bkup_basename, download_tmp_dir))
        res = sh("md5sum %s | awk '{print $1}'", [File.expand_path(bkup_basename, download_tmp_dir)])
        
        evcb.setattr(res[:stdout].chomp, alloc_size)

        # upload image file
        snapshot_stg.upload(File.expand_path(bkup_basename, download_tmp_dir), bo)
        evcb.progress(100)
      ensure
        clean_snapshot_for_backup()
        File.unlink(File.expand_path(bkup_basename, download_tmp_dir)) rescue nil
      end

      protected

      def vmimg_cache_dir
        Dcmgr.conf.local_store.image_cache_dir
      end

      def download_tmp_dir
        ENV['TMPDIR'] || ENV['TMP'] || '/var/tmp'
      end
      
      def vmimg_cache_path(img_id)
        File.expand_path(img_id, (Dcmgr.conf.local_store.enable_image_caching ? vmimg_cache_dir : download_tmp_dir))
      end

      def download_to_local_cache(img_src_uri, basename, checksum)
        begin
          if File.mtime(vmimg_cache_path(basename)) <= File.mtime("#{vmimg_cache_path(basename)}.md5")
            cached_chksum = File.read("#{vmimg_cache_path(basename)}.md5").chomp
            if cached_chksum == checksum
              # Here is the only case to be able to use valid cached
              # image file.
              logger.info("Checksum verification passed: #{vmimg_cache_path(basename)}. We will use this copy.")
              return
            else
              logger.warn("Checksum verification failed: #{vmimg_cache_path(basename)}. #{cached_chksum} (calced) != #{checksum} (expected)")
            end
          else
            logger.warn("Checksum cache file is older than the image file: #{vmimg_cache_path(basename)}")
          end
        rescue SystemCallError => e
          # come here if it got failed with
          # File.mtime()/read(). Expected to catch ENOENT, EACCESS normally.
          logger.error("Failed to check cached image or checksum file: #{e.message}: #{vmimg_cache_path(basename)}")
        end

        # Any failure cases will reach here to download image file.
        
        File.unlink("#{vmimg_cache_path(basename)}") rescue nil
        File.unlink("#{vmimg_cache_path(basename)}.md5") rescue nil
        
        paralell_curl(img_src_uri, vmimg_cache_path(basename))
        
        if Dcmgr.conf.local_store.enable_cache_checksum
          logger.debug("calculating checksum of #{vmimg_cache_path(basename)}")
          sh("md5sum #{vmimg_cache_path(basename)} | awk '{print $1}' > #{vmimg_cache_path(basename)}.md5")
        end
      end

      def take_snapshot_for_backup()
      end
      def clean_snapshot_for_backup()
      end

      private
      def paralell_curl(url, output_path)
        logger.debug("downloading #{url} as #{output_path}")
        sh("#{Dcmgr.conf.script_root_path}/pararell-curl.sh --url=#{url} --output_path=#{output_path}")
      end
    end
  end
end
