# -*- coding: utf-8 -*-
module Hijiki::DcmgrResource::V1203
  class Instance < Base
    module ClassMethods
      def list(params = {})
        self.find(:all,:params => params.merge({:state=>'alive_with_terminated'}))
      end
      
      def show(uuid)
        self.get(uuid)
      end
      
      def create(params)
        instance = self.new
        instance.image_id = params[:image_id]
        instance.instance_spec_id = params[:instance_spec_id]
        instance.host_pool_id = params[:host_pool_id]
        instance.host_name = params[:host_name]
        instance.user_data = params[:user_data]
        instance.security_groups = params[:security_groups]
        instance.ssh_key_id = params[:ssh_key]
        instance.display_name = params[:display_name]

        instance.vifs = params[:vifs] if params[:vifs]

        is = InstanceSpec.show(params[:instance_spec_id]) || raise("Unknown instance spec: #{params[instance_spec_id]}")
        instance.cpu_cores = is.cpu_cores
        instance.memory_size = is.memory_size
        instance.hypervisor = is.hypervisor
        instance.quota_weight = is.quota_weight

        instance.save
        instance
      end
      
      def destroy(instance_id)
        self.delete(instance_id).body
      end
      
      def reboot(instance_id)
        @collection ||= self.collection_name
        self.collection_name = File.join(@collection,instance_id)
        result = self.put(:reboot)
        self.collection_name = @collection
        result.body
      end

      def start(instance_id)
        @collection ||= self.collection_name
        self.collection_name = File.join(@collection,instance_id)
        result = self.put(:start)
        self.collection_name = @collection
        result.body
      end

      def stop(instance_id)
        @collection ||= self.collection_name
        self.collection_name = File.join(@collection,instance_id)
        result = self.put(:stop)
        self.collection_name = @collection
        result.body
      end

      def update(instance_id,params)
        self.put(instance_id,params).body
      end

      def backup(instance_id)
        result = self.find(instance_id).put(:backup)
        result.body
      end
    end
    extend ClassMethods
  end
end
