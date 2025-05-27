# Ensure lib directory is in load path
$LOAD_PATH.unshift(Rails.root.join('lib'))

# Load protobuf files explicitly
require Rails.root.join('lib/proto/mule_pb')
require Rails.root.join('lib/proto/mule_services_pb')

require_relative '../../lib/grpc_server'

Rails.application.configure do
  config.after_initialize do
    grpc_port = ENV.fetch('GRPC_PORT', 50051).to_i
    grpc_host = ENV.fetch('GRPC_HOST', '0.0.0.0')
    
    Thread.new do
      server = GRPC::RpcServer.new
      server.add_http2_port("#{grpc_host}:#{grpc_port}", :this_port_is_insecure)
      server.handle(MuleManagerServer.new)
      
      Rails.logger.info "Starting gRPC server on #{grpc_host}:#{grpc_port}"
      server.run_till_terminated_or_interrupted([1, 'int', 'SIGQUIT'])
    end
  end
end