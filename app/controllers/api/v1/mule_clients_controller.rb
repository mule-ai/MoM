class Api::V1::MuleClientsController < ActionController::API
  def index
    render json: { clients: MuleClientManager.instance.all_clients }
  end

  def show
    client = MuleClientManager.instance.find_client(params[:id])
    if client
      render json: { client: client }
    else
      render json: { error: 'Client not found' }, status: :not_found
    end
  end

  def create
    client_data = client_params
    client = MuleClientManager.instance.register_client(client_data)
    render json: { client: client }, status: :created
  end

  def destroy
    success = MuleClientManager.instance.deregister_client(params[:id])
    if success
      render json: { message: 'Client deregistered successfully' }
    else
      render json: { error: 'Client not found' }, status: :not_found
    end
  end

  def execute_workflow
    client_id = params[:id]
    workflow_data = workflow_params
    
    result = MuleClientManager.instance.execute_workflow(client_id, workflow_data)
    
    if result[:success]
      render json: result
    else
      render json: result, status: :unprocessable_entity
    end
  end

  def status
    client = MuleClientManager.instance.find_client(params[:id])
    if client
      render json: { 
        client: client,
        running_workflows: MuleClientManager.instance.get_running_workflows(params[:id])
      }
    else
      render json: { error: 'Client not found' }, status: :not_found
    end
  end

  private

  def client_params
    params.require(:client).permit(:name, :host, :port, capabilities: [])
  end

  def workflow_params
    params.require(:workflow).permit(:workflow_name, :prompt, :repository_path, parameters: {})
  end
end