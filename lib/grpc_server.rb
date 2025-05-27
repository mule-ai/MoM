require 'grpc'

# Load protobuf files with error handling
begin
  require_relative 'proto/mule_pb'
  require_relative 'proto/mule_services_pb'
rescue LoadError => e
  Rails.logger.error "Failed to load protobuf files: #{e.message}"
  Rails.logger.error "Current directory: #{Dir.pwd}"
  Rails.logger.error "Proto files available: #{Dir.glob('lib/proto/*.rb')}"
  raise
end

class MuleManagerServer < Mule::MuleManagerService::Service
  def initialize
    @clients = {}
  end

  def register_mule_client(request, _unused_call)
    client_id = SecureRandom.uuid
    
    client = Mule::MuleClient.new(
      id: client_id,
      name: request.name,
      host: request.host,
      port: request.port,
      status: 'active',
      last_heartbeat: Time.now.to_i,
      capabilities: request.capabilities
    )
    
    @clients[client_id] = client
    
    Mule::RegisterMuleClientResponse.new(
      client_id: client_id,
      success: true,
      message: "Client registered successfully"
    )
  end

  def get_mule_clients(_request, _unused_call)
    Mule::GetMuleClientsResponse.new(
      clients: @clients.values
    )
  end

  def execute_workflow_on_client(request, _unused_call)
    client = @clients[request.client_id]
    
    unless client
      return Mule::ExecuteWorkflowResponse.new(
        execution_id: "",
        success: false,
        message: "Client not found"
      )
    end

    execution_id = SecureRandom.uuid
    
    Thread.new do
      execute_workflow_async(client, request, execution_id)
    end
    
    Mule::ExecuteWorkflowResponse.new(
      execution_id: execution_id,
      success: true,
      message: "Workflow execution started"
    )
  end

  def get_client_status(request, _unused_call)
    client = @clients[request.client_id]
    
    unless client
      return Mule::GetClientStatusResponse.new(
        client: nil,
        running_workflows: []
      )
    end
    
    Mule::GetClientStatusResponse.new(
      client: client,
      running_workflows: []
    )
  end

  def deregister_mule_client(request, _unused_call)
    if @clients.delete(request.client_id)
      Mule::DeregisterMuleClientResponse.new(
        success: true,
        message: "Client deregistered successfully"
      )
    else
      Mule::DeregisterMuleClientResponse.new(
        success: false,
        message: "Client not found"
      )
    end
  end

  private

  def execute_workflow_async(client, request, execution_id)
    begin
      conn = GRPC::Core::Channel.new("#{client.host}:#{client.port}", {}, :this_channel_is_insecure)
      stub = Mule::MuleService::Stub.new(nil, nil, channel_override: conn)
      
      workflow_request = Mule::ExecuteWorkflowRequest.new(
        workflow_name: request.workflow_name,
        prompt: request.prompt,
        path: request.repository_path
      )
      
      response = stub.execute_workflow(workflow_request)
      Rails.logger.info "Workflow execution completed: #{response.inspect}"
      
    rescue => e
      Rails.logger.error "Workflow execution failed: #{e.message}"
    end
  end
end