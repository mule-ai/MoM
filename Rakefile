require_relative "config/application"

Rails.application.load_tasks

task :generate_grpc do
  sh "grpc_tools_ruby_protoc -I lib/proto --ruby_out=lib/proto --grpc_out=lib/proto lib/proto/mule.proto"
end