require 'singleton'
require 'securerandom'

class MuleClientManager
  include Singleton

  def initialize
    @running_workflows = {}
  end

  def register_client(client_data, force: false)
    # Test connection unless forced
    unless force
      heartbeat_result = test_client_connection(client_data[:host], client_data[:port])
      unless heartbeat_result[:success]
        raise "Failed to connect to client: #{heartbeat_result[:error]}"
      end
    end
    
    # Create the client record
    client = MuleClient.create!(
      name: client_data[:name],
      host: client_data[:host],
      port: client_data[:port],
      status: force ? 'unverified' : 'active',
      last_heartbeat: Time.current,
      capabilities: client_data[:capabilities] || []
    )
    
    Rails.logger.info "Registered new Mule client: #{client.name} (#{client.id})"
    
    # Return client as hash for compatibility
    {
      id: client.id.to_s,
      name: client.name,
      host: client.host,
      port: client.port,
      status: client.status,
      last_heartbeat: client.last_heartbeat_timestamp,
      capabilities: client.capabilities
    }
  end

  def test_client_connection(host, port)
    begin
      require 'grpc'
      require_relative '../../lib/proto/mule_client_pb'
      require_relative '../../lib/proto/mule_client_services_pb'
      
      Rails.logger.info "Testing connection to #{host}:#{port}"
      
      # Test basic network connectivity first  
      conn = GRPC::Core::Channel.new("#{host}:#{port}", {}, :this_channel_is_insecure)
      stub = Mule::V1::MuleService::Stub.new(nil, nil, channel_override: conn)
      
      Rails.logger.info "gRPC stub created, attempting heartbeat call"
      
      # Set a short timeout for the heartbeat check
      response = stub.get_heartbeat(Mule::V1::HeartbeatRequest.new, deadline: Time.now + 10)
      
      Rails.logger.info "Heartbeat successful: #{response.inspect}"
      { success: true, response: response }
    rescue GRPC::Unavailable => e
      Rails.logger.error "gRPC service unavailable: #{e.message}"
      { success: false, error: "Service unavailable at #{host}:#{port} - #{e.message}" }
    rescue GRPC::DeadlineExceeded => e
      Rails.logger.error "gRPC timeout: #{e.message}"
      { success: false, error: "Connection timeout to #{host}:#{port}" }
    rescue GRPC::Unimplemented => e
      Rails.logger.error "gRPC method not implemented: #{e.message}"
      { success: false, error: "GetHeartbeat method not supported by server at #{host}:#{port}" }
    rescue => e
      Rails.logger.error "gRPC connection failed: #{e.class} - #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      { success: false, error: "Connection failed: #{e.message}" }
    end
  end

  def get_client_providers(client_id)
    client = MuleClient.find_by(id: client_id)
    return [] unless client
    
    begin
      require 'grpc'
      require_relative '../../lib/proto/mule_client_pb'
      require_relative '../../lib/proto/mule_client_services_pb'
      
      conn = GRPC::Core::Channel.new("#{client[:host]}:#{client[:port]}", {}, :this_channel_is_insecure)
      stub = Mule::V1::MuleService::Stub.new(nil, nil, channel_override: conn)
      
      response = stub.list_providers(Mule::V1::ListProvidersRequest.new, deadline: Time.now + 10)
      response.providers.sort_by { |provider| provider.name }.map do |provider|
        {
          name: provider.name,
          type: 'unknown',  # Provider type not available in Mule protobuf
          status: 'active'   # Assume active if listed
        }
      end
    rescue => e
      Rails.logger.error "Failed to get providers for client #{client_id}: #{e.message}"
      []
    end
  end

  def get_client_agents(client_id)
    client = MuleClient.find_by(id: client_id)
    return [] unless client
    
    begin
      require 'grpc'
      require_relative '../../lib/proto/mule_client_pb'
      require_relative '../../lib/proto/mule_client_services_pb'
      
      conn = GRPC::Core::Channel.new("#{client[:host]}:#{client[:port]}", {}, :this_channel_is_insecure)
      stub = Mule::V1::MuleService::Stub.new(nil, nil, channel_override: conn)
      
      response = stub.list_agents(Mule::V1::ListAgentsRequest.new, deadline: Time.now + 10)
      response.agents.sort_by { |agent| agent.name }.map do |agent|
        {
          id: agent.id.to_s,
          name: agent.name,
          status: 'active',  # Assume active if listed
          last_used: Time.now - rand(1..72).hours, # Placeholder since we don't have this data
          provider: agent.provider_name,
          model: agent.model
        }
      end
    rescue => e
      Rails.logger.error "Failed to get agents for client #{client_id}: #{e.message}"
      []
    end
  end

  def get_client_workflows(client_id)
    client = MuleClient.find_by(id: client_id)
    return [] unless client
    
    begin
      require 'grpc'
      require_relative '../../lib/proto/mule_client_pb'
      require_relative '../../lib/proto/mule_client_services_pb'
      
      conn = GRPC::Core::Channel.new("#{client[:host]}:#{client[:port]}", {}, :this_channel_is_insecure)
      stub = Mule::V1::MuleService::Stub.new(nil, nil, channel_override: conn)
      
      response = stub.list_workflows(Mule::V1::ListWorkflowsRequest.new, deadline: Time.now + 10)
      response.workflows.sort_by { |workflow| workflow.name }.map do |workflow|
        {
          name: workflow.name,
          description: workflow.description || "No description available"
        }
      end
    rescue => e
      Rails.logger.error "Failed to get workflows for client #{client_id}: #{e.message}"
      []
    end
  end

  def deregister_client(client_id)
    client = MuleClient.find_by(id: client_id)
    @running_workflows.delete(client_id)
    
    if client
      Rails.logger.info "Deregistered Mule client: #{client.name} (#{client_id})"
      client.destroy
      true
    else
      false
    end
  end

  def find_client(client_id)
    client = MuleClient.find_by(id: client_id)
    return nil unless client
    
    {
      id: client.id.to_s,
      name: client.name,
      host: client.host,
      port: client.port,
      status: client.status,
      last_heartbeat: client.last_heartbeat_timestamp,
      capabilities: client.capabilities
    }
  end

  def all_clients
    MuleClient.all.map do |client|
      {
        id: client.id.to_s,
        name: client.name,
        host: client.host,
        port: client.port,
        status: client.status,
        last_heartbeat: client.last_heartbeat_timestamp,
        capabilities: client.capabilities
      }
    end
  end

  def execute_workflow(client_id, workflow_data)
    client_record = MuleClient.find_by(id: client_id)
    
    unless client_record
      return { success: false, message: 'Client not found' }
    end
    
    client = {
      id: client_record.id.to_s,
      host: client_record.host,
      port: client_record.port
    }

    execution_id = SecureRandom.uuid
    
    workflow_execution = {
      id: execution_id,
      workflow_name: workflow_data[:workflow_name],
      status: 'running',
      started_at: Time.now.to_i,
      prompt: workflow_data[:prompt],
      repository_path: workflow_data[:repository_path],
      parameters: workflow_data[:parameters] || {}
    }
    
    @running_workflows[client_id] ||= []
    @running_workflows[client_id] << workflow_execution
    
    Thread.new do
      execute_workflow_on_client(client, workflow_data, execution_id)
    end
    
    {
      success: true,
      execution_id: execution_id,
      message: 'Workflow execution started'
    }
  end

  def get_running_workflows(client_id)
    @running_workflows[client_id] || []
  end

  private

  def execute_workflow_on_client(client, workflow_data, execution_id)
    begin
      require 'grpc'
      require_relative '../../lib/proto/mule_client_pb'
      require_relative '../../lib/proto/mule_client_services_pb'
      
      conn = GRPC::Core::Channel.new("#{client[:host]}:#{client[:port]}", {}, :this_channel_is_insecure)
      stub = Mule::V1::MuleService::Stub.new(nil, nil, channel_override: conn)
      
      request = Mule::V1::ExecuteWorkflowRequest.new(
        workflow_name: workflow_data[:workflow_name],
        prompt: workflow_data[:prompt],
        path: workflow_data[:repository_path]
      )
      
      response = stub.execute_workflow(request)
      
      update_workflow_status(client[:id], execution_id, 'completed')
      Rails.logger.info "Workflow execution completed: #{response.inspect}"
      
    rescue => e
      update_workflow_status(client[:id], execution_id, 'failed')
      Rails.logger.error "Workflow execution failed: #{e.message}"
    end
  end

  def update_workflow_status(client_id, execution_id, status)
    workflows = @running_workflows[client_id]
    return unless workflows
    
    workflow = workflows.find { |w| w[:id] == execution_id }
    workflow[:status] = status if workflow
    
    if status == 'completed' || status == 'failed'
      @running_workflows[client_id].reject! { |w| w[:id] == execution_id }
    end
  end
end