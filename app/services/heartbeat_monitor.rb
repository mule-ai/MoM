require 'singleton'

class HeartbeatMonitor
  include Singleton

  POLL_INTERVAL = 60.seconds # Poll every minute
  HEARTBEAT_TIMEOUT = 120.seconds # Mark inactive after 2 minutes
  
  def initialize
    @running = false
    @thread = nil
  end

  def start
    return if @running

    @running = true
    @thread = Thread.new do
      Rails.logger.info "HeartbeatMonitor started - polling every #{POLL_INTERVAL} seconds"
      
      while @running
        begin
          poll_all_clients
        rescue => e
          Rails.logger.error "HeartbeatMonitor error: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
        end
        
        sleep(POLL_INTERVAL)
      end
    end
  end

  def stop
    @running = false
    @thread&.join(5) # Wait up to 5 seconds for thread to finish
    Rails.logger.info "HeartbeatMonitor stopped"
  end

  def running?
    @running
  end

  def trigger_immediate_check
    Rails.logger.info "Manual heartbeat check triggered"
    poll_all_clients
  end

  private

  def poll_all_clients
    clients = MuleClient.all
    Rails.logger.info "HeartbeatMonitor: Polling #{clients.count} clients for heartbeat"

    clients.each do |client|
      Rails.logger.info "HeartbeatMonitor: Processing client #{client.name} (current status: #{client.status})"
      check_client_heartbeat(client)
    end
    
    Rails.logger.info "HeartbeatMonitor: Completed polling cycle"
  end

  def check_client_heartbeat(client)
    Rails.logger.info "Checking heartbeat for client #{client.name} (#{client.address})"
    
    # Always perform actual heartbeat check first
    manager = MuleClientManager.instance
    result = manager.test_client_connection(client.host, client.port)
    
    if result[:success]
      # Client is responding - update heartbeat and ensure it's active
      updates = { last_heartbeat: Time.current }
      if client.status != 'active'
        updates[:status] = 'active'
        Rails.logger.info "Client #{client.name} is back online - marking as active"
      else
        Rails.logger.debug "Client #{client.name} heartbeat successful"
      end
      client.update!(updates)
    else
      # Client is not responding - mark as inactive
      Rails.logger.warn "Client #{client.name} failed heartbeat - marking as inactive: #{result[:error]}"
      client.update!(status: 'inactive') if client.status != 'inactive'
    end
  rescue => e
    Rails.logger.error "Failed to check heartbeat for client #{client.name}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    if client.status == 'active'
      client.update!(status: 'inactive')
    end
  end
end