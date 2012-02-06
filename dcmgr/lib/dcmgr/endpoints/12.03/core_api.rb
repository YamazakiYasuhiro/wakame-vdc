# -*- coding: utf-8 -*-

require 'sinatra/base'
require 'sinatra/namespace'
require 'sinatra/sequel_transaction'

require 'json'
require 'extlib/hash'

require 'dcmgr/endpoints/errors'

module Dcmgr::Endpoints::V1203
  class CoreAPI < Sinatra::Base
    include Dcmgr::Logger
    register Sinatra::Namespace
    register Sinatra::SequelTransaction

    use Dcmgr::Rack::RequestLogger

    # To access constants in this namespace
    include Dcmgr::Endpoints

    M = Dcmgr::Models
    E = Dcmgr::Endpoints::Errors

    disable :sessions
    disable :show_exceptions

    before do
      @params = parsed_request_body if request.post?
      if request.env[HTTP_X_VDC_ACCOUNT_UUID].to_s == ''
        raise E::InvalidRequestCredentials
      else
        begin
          # find or create account entry.
          @account = M::Account[request.env[HTTP_X_VDC_ACCOUNT_UUID]] || \
          M::Account.create(:uuid=>M::Account.trim_uuid(request.env[HTTP_X_VDC_ACCOUNT_UUID]))
        rescue => e
          logger.error(e)
          raise E::InvalidRequestCredentials, "#{e.message}"
        end
        raise E::InvalidRequestCredentials if @account.nil?
      end

      @requester_token = request.env[HTTP_X_VDC_REQUESTER_TOKEN]
      #@frontend = M::FrontendSystem[request.env[RACK_FRONTEND_SYSTEM_ID]]

      #raise E::InvalidRequestCredentials if !(@account && @frontend)
      raise E::DisabledAccount if @account.disable?
    end

    def find_by_uuid(model_class, uuid)
      if model_class.is_a?(Symbol)
        model_class = Dcmgr::Models.const_get(model_class)
      end
      model_class[uuid] || raise(E::UnknownUUIDResource, uuid.to_s)
    end

    def find_account(account_uuid)
      find_by_uuid(:Account, account_uuid)
    end

    # Returns deserialized hash from HTTP body. Serialization fromat
    # is guessed from content type header. The query string params
    # is returned if none of content type header is in HTTP headers.
    # This method is called only when the request method is POST.
    def parsed_request_body
      # @mime_types should be defined by sinatra/respond_to.rb plugin.
      if @mime_types.nil?
        # use query string as requested params if Content-Type
        # header was not sent.
        # ActiveResource library tells the one level nested hash which has
        # {'something key'=>real_params} so that dummy key is assinged here.
        hash = {:dummy=>@params}
      else
        mime = @mime_types.first
        begin
          case mime.to_s
          when 'application/json', 'text/json'
            require 'json'
            hash = JSON.load(request.body)
            hash = hash.to_mash
          when 'application/yaml', 'text/yaml'
            require 'yaml'
            hash = YAML.load(request.body)
            hash = hash.to_mash
          else
            raise "Unsupported body document type: #{mime.to_s}"
          end
        rescue => e
          # fall back to query string params
          hash = {:dummy=>@params}
        end
      end
      return hash.values.first
    end

    def response_to(res)
      mime = @mime_types.first unless @mime_types.nil?
      case mime.to_s
      when 'application/yaml', 'text/yaml'
        content_type 'yaml'
        body res.to_yaml
      when 'application/xml', 'text/xml'
        raise NotImplementedError
      else
        content_type 'json'
        body res.to_json(JSON::PRETTY_STATE_PROTOTYPE)
      end
    end

    # I am not going to use error(ex, &blk) hook since it works only
    # when matches the Exception class exactly. I expect to match
    # whole subclasses of APIError so that override handle_exception!().
    def handle_exception!(boom)
      # Translate common non-APIError to APIError
      boom = case boom
             when Sequel::DatabaseError
               DatabaseError.new
             else
               boom
             end

      if boom.kind_of?(Dcmgr::Endpoints::APIError)
        @env['sinatra.error'] = boom
        Dcmgr::Logger.create('API Error').error("#{request.path_info} -> #{boom.class.to_s}: #{boom.message} (#{boom.backtrace.first})")
        error(boom.status_code, response_to({:error=>boom.class.to_s, :message=>boom.message, :code=>boom.error_code}))
      else
        logger.error(boom)
        super
      end
    end

    def find_volume_snapshot(snapshot_id)
      vs = M::VolumeSnapshot[snapshot_id]
      raise E::UnknownVolumeSnapshot if vs.nil?
      raise E::InvalidVolumeState unless vs.state.to_s == 'available'
      vs
    end

    def examine_owner(account_resource)
      if @account.canonical_uuid == account_resource.account_id ||
          @account.canonical_uuid == 'a-00000000'
        return true
      else
        return false
      end
    end

    def select_index(model_class, data)
      if model_class.is_a?(Symbol)
        model_class = M.const_get(model_class)
      end

      start = data[:start].to_i
      start = start < 1 ? 0 : start
      limit = data[:limit].to_i
      limit = limit < 1 ? nil : limit

      if [M::InstanceSpec.to_s].member?(model_class.to_s)
        total_ds = model_class.where(:account_id=>[@account.canonical_uuid,
                                                   M::Account::SystemAccount::SharedPoolAccount.uuid,
                                                  ])
      else
        total_ds = model_class.where(:account_id=>@account.canonical_uuid)
      end

      if [M::Instance.to_s, M::Volume.to_s, M::VolumeSnapshot.to_s].member?(model_class.to_s)
        total_ds = total_ds.alives_and_recent_termed
      end
      if [M::Image.to_s].member?(model_class.to_s)
        total_ds = total_ds.or(:is_public=>true)
      end

      partial_ds  = total_ds.dup.order(:id.desc)
      partial_ds = partial_ds.limit(limit, start) if limit.is_a?(Integer)

      results = partial_ds.all.map {|i|
        if [M::Image.to_s].member?(model_class.to_s)
          i.to_api_document(@account.canonical_uuid)
        else
          i.to_api_document
        end
      }

      res = [{
               :owner_total => total_ds.count,
               :start => start,
               :limit => limit,
               :results=> results
             }]
    end

    def self.load_namespace(ns)
      #load File.expand_path("../#{ns}.rb", __FILE__)
      # workaround for Rubinius
      fname = File.expand_path("../#{ns}.rb", __FILE__)
      eval(File.read(fname), binding, fname)
    end

    # Endpoint to handle VM instance.
    load_namespace('instances')

    load_namespace('images')

    load_namespace('host_nodes')

    load_namespace('volumes')



    namespace '/volume_snapshots' do
      get do
        # description 'Show lists of the volume_snapshots'
        # params start, fixnum, optional
        # params limit, fixnum, optional
        res = select_index(:VolumeSnapshot, {:start => params[:start],
                             :limit => params[:limit]})
        response_to(res)
      end

      get '/upload_destination' do
        c = StorageService::snapshot_repository_config.dup
        tmp = c['local']
        c.delete('local')
        results = {}
        results = c.collect {|item| {
            :destination_id => item[0],
            :destination_name => item[1]["display_name"]
          }
        }
        results.unshift({
                          :destination_id => 'local',
                          :destination_name => tmp['display_name']
                        })
        response_to([{:results => results}])
      end

      get '/:id' do
        # description 'Show the volume status'
        # params id, string, required
        snapshot_id = params[:id]
        raise E::UndefinedVolumeSnapshotID if snapshot_id.nil?
        vs = find_by_uuid(:VolumeSnapshot, snapshot_id)
        response_to(vs.to_api_document)
      end

      post do
        # description 'Create a new volume snapshot'
        # params volume_id, string, required
        # params detination, string, required
        # params storage_pool_id, string, optional
        raise E::UndefinedVolumeID if params[:volume_id].nil?

        v = find_by_uuid(:Volume, params[:volume_id])
        raise E::UnknownVolume if v.nil?
        raise E::InvalidVolumeState unless v.ready_to_take_snapshot?
        vs = v.create_snapshot(@account.canonical_uuid)
        sp = vs.storage_node
        destination_key = Dcmgr::StorageService.destination_key(@account.canonical_uuid, params[:destination], sp.snapshot_base_path, vs.snapshot_filename)
        vs.update_destination_key(@account.canonical_uuid, destination_key)
        commit_transaction

        repository_address = Dcmgr::StorageService.repository_address(destination_key)
        res = Dcmgr.messaging.submit("sta-handle.#{sp.node_id}", 'create_snapshot', vs.canonical_uuid, repository_address)
        response_to(vs.to_api_document)
      end

      delete '/:id' do
        # description 'Delete the volume snapshot'
        # params id, string, required
        snapshot_id = params[:id]
        raise E::UndefindVolumeSnapshotID if snapshot_id.nil?

        v = find_by_uuid(:VolumeSnapshot, snapshot_id)
        raise E::UnknownVolumeSnapshot if v.nil?
        raise E::InvalidVolumeState unless v.state == "available"

        destination_key = v.destination_key

        begin
          vs  = M::VolumeSnapshot.delete_snapshot(@account.canonical_uuid, snapshot_id)
        rescue M::VolumeSnapshot::RequestError => e
          logger.error(e)
          raise E::InvalidDeleteRequest
        end
        raise E::UnknownVolumeSnapshot if vs.nil?
        sp = vs.storage_node

        commit_transaction

        repository_address = Dcmgr::StorageService.repository_address(destination_key)
        res = Dcmgr.messaging.submit("sta-handle.#{sp.node_id}", 'delete_snapshot', vs.canonical_uuid, repository_address)
        response_to([vs.canonical_uuid])
      end
    end

    load_namespace('security_groups')

    load_namespace('storage_nodes')

    load_namespace('ssh_key_pairs')

    namespace '/networks' do
      # description "Networks for account"
      get do
        # description "List networks in account"
        # params start, fixnum, optional
        # params limit, fixnum, optional
        res = select_index(:Network, {:start => params[:start],
                             :limit => params[:limit]})
        response_to(res)
      end

      get '/:id' do
        # description "Retrieve details about a network"
        # params :id required
        nw = find_by_uuid(:Network, params[:id])
        examine_owner(nw) || raise(E::OperationNotPermitted)

        response_to(nw.to_api_document)
      end

      post do
        # description "Create new network"
        # params :gw required default gateway address of the network
        # params :network required network address of the network
        # params :prefix optional  netmask bit length. it will be
        #               set 24 if none.
        # params :description optional description for the network
        savedata = {
          :account_id=>@account.canonical_uuid,
          :ipv4_gw => params[:gw],
          :ipv4_network => params[:network],
          :prefix => params[:prefix].to_i,
          :description => params[:description],
        }
        nw = M::Network.create(savedata)

        response_to(nw.to_api_document)
      end

      delete '/:id' do
        # description "Remove network information"
        # params :id required
        nw = find_by_uuid(:Network, params[:id])
        examine_owner(nw) || raise(E::OperationNotPermitted)
        nw.destroy

        response_to([nw.canonical_uuid])
      end

      put '/:id/dhcp/reserve' do
        # description 'Register reserved IP address to the network'
        # params id, string, required
        # params ipaddr, [String,Array], required
        nw = find_by_uuid(:Network, params[:id])
        examine_owner(nw) || raise(E::OperationNotPermitted)

        (params[:ipaddr].is_a?(Array) ? params[:ipaddr] : Array(params[:ipaddr])).each { |ip|
          nw.ip_lease_dataset.add_reserved(ip)
        }
        response_to({})
      end
      
      put '/:id/dhcp/release' do
        # description 'Unregister reserved IP address from the network'
        # params id, string, required
        # params ipaddr, [String,Array], required
        nw = find_by_uuid(:Network, params[:id])
        examine_owner(nw) || raise(E::OperationNotPermitted)
        
        (params[:ipaddr].is_a?(Array) ? params[:ipaddr] : Array(params[:ipaddr])).each { |ip|
          nw.ip_lease_dataset.delete_reserved(ip)
        }
        response_to({})
      end
    end
    
  end
end
