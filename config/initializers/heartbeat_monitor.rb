Rails.application.config.after_initialize do
  # Start the heartbeat monitor in a separate thread
  # This will continuously monitor all registered mule clients
  HeartbeatMonitor.instance.start
  
  # Gracefully shutdown the monitor when the application stops
  at_exit do
    HeartbeatMonitor.instance.stop
  end
end