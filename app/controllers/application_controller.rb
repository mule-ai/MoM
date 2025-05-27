class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception, unless: -> { request.format.json? }
  
  def health
    render json: {
      status: "ok",
      service: "MoM - Mule of Mules",
      version: "1.0.0",
      timestamp: Time.current.iso8601,
      grpc_enabled: true,
      grpc_port: ENV.fetch('GRPC_PORT', 50051)
    }
  end
end