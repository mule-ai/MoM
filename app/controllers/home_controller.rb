class HomeController < ApplicationController
  def index
    @clients = MuleClientManager.instance.all_clients
    @system_status = {
      total_clients: @clients.size,
      active_clients: @clients.count { |c| c[:status] == 'active' },
      inactive_clients: @clients.count { |c| c[:status] == 'inactive' },
      grpc_port: ENV.fetch('GRPC_PORT', 50051),
      monitor_status: HeartbeatMonitor.instance.running? ? 'active' : 'inactive',
      uptime: Time.current.iso8601
    }
  end

  def trigger_heartbeat
    HeartbeatMonitor.instance.trigger_immediate_check
    redirect_to root_path, notice: "Heartbeat check triggered manually. Check logs for results."
  end
end