class MuleClientsController < ApplicationController
  before_action :set_client, only: [:show, :destroy, :execute_workflow, :status]

  def index
    redirect_to root_path
  end

  def show
    @client = MuleClientManager.instance.find_client(params[:id])
    redirect_to root_path, alert: 'Client not found' unless @client
    
    @running_workflows = MuleClientManager.instance.get_running_workflows(params[:id])
    
    # Get real data from the Mule client
    @providers = MuleClientManager.instance.get_client_providers(params[:id])
    @agents = MuleClientManager.instance.get_client_agents(params[:id])  
    @workflows = MuleClientManager.instance.get_client_workflows(params[:id])
  end

  def new
    @client = {}
  end

  def create
    client_data = client_params.to_h.symbolize_keys
    client_data[:capabilities] = client_data[:capabilities].split(',').map(&:strip) if client_data[:capabilities].present?
    
    force = params[:force] == 'true'
    
    begin
      @client = MuleClientManager.instance.register_client(client_data, force: force)
      redirect_to root_path, notice: 'Mule client registered successfully'
    rescue => e
      if force
        redirect_to root_path, alert: "Failed to register client: #{e.message}"
      else
        # Show form with error and option to force add
        @error_message = e.message
        @client_data = client_data
        render :new
      end
    end
  end

  def destroy
    if MuleClientManager.instance.deregister_client(params[:id])
      redirect_to root_path, notice: 'Client removed successfully'
    else
      redirect_to root_path, alert: 'Client not found'
    end
  end

  def execute_workflow
    workflow_data = workflow_params.to_h.symbolize_keys
    result = MuleClientManager.instance.execute_workflow(params[:id], workflow_data)
    
    if result[:success]
      redirect_to mule_client_path(params[:id]), notice: 'Workflow execution started'
    else
      redirect_to mule_client_path(params[:id]), alert: result[:message]
    end
  end

  def status
    @client = MuleClientManager.instance.find_client(params[:id])
    @running_workflows = MuleClientManager.instance.get_running_workflows(params[:id])
    
    render json: {
      client: @client,
      running_workflows: @running_workflows
    }
  end

  private

  def set_client
    @client = MuleClientManager.instance.find_client(params[:id])
  end

  def client_params
    params.require(:client).permit(:name, :host, :port, :capabilities)
  end

  def workflow_params
    params.require(:workflow).permit(:workflow_name, :prompt, :repository_path)
  end

  def mock_providers
    [
      { name: 'OpenAI', type: 'openai', status: 'active' },
      { name: 'Anthropic', type: 'anthropic', status: 'active' },
      { name: 'Local Model', type: 'local', status: 'inactive' }
    ]
  end

  def mock_agents
    [
      { id: 'agent-1', name: 'Code Generator', status: 'active', last_used: 2.hours.ago },
      { id: 'agent-2', name: 'Bug Fixer', status: 'active', last_used: 1.day.ago },
      { id: 'agent-3', name: 'Documentation Writer', status: 'idle', last_used: 3.days.ago }
    ]
  end

  def mock_workflows
    [
      { name: 'Code Generation', description: 'Generate new code based on requirements' },
      { name: 'Bug Fix', description: 'Analyze and fix bugs in existing code' },
      { name: 'Code Review', description: 'Review code for quality and best practices' },
      { name: 'Documentation', description: 'Generate or update documentation' }
    ]
  end
end