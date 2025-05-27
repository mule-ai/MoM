# MoM (Mule of Mules)

MoM is a Ruby on Rails manager for Mule AI agents. It provides centralized management and coordination of multiple Mule instances through both REST API and gRPC interfaces.

## Features

- **Client Management**: Register, monitor, and manage multiple Mule AI clients
- **Workflow Orchestration**: Execute workflows across different Mule instances
- **gRPC Integration**: High-performance gRPC server for real-time communication
- **REST API**: HTTP endpoints for web-based integrations
- **Status Monitoring**: Track client health and workflow execution status

## Quick Start

1. Install dependencies:
   ```bash
   bundle install
   ```

2. Generate gRPC code:
   ```bash
   rake generate_grpc
   ```

3. Setup database:
   ```bash
   rails db:create db:migrate
   ```

4. Start the server:
   ```bash
   rails server
   ```

The gRPC server will start automatically on port 50051 (configurable via `GRPC_PORT` environment variable).

## API Endpoints

### REST API

- `GET /api/v1/mule_clients` - List all registered clients
- `POST /api/v1/mule_clients` - Register a new client
- `GET /api/v1/mule_clients/:id` - Get client details
- `DELETE /api/v1/mule_clients/:id` - Deregister a client
- `POST /api/v1/mule_clients/:id/execute_workflow` - Execute workflow on client
- `GET /api/v1/mule_clients/:id/status` - Get client status and running workflows

### gRPC Service

The `MuleManagerService` provides equivalent functionality through gRPC:

- `RegisterMuleClient` - Register a new Mule client
- `GetMuleClients` - List all registered clients
- `ExecuteWorkflowOnClient` - Execute a workflow on a specific client
- `GetClientStatus` - Get client status and running workflows
- `DeregisterMuleClient` - Remove a client from management

## Configuration

Environment variables:

- `GRPC_PORT` - gRPC server port (default: 50051)
- `GRPC_HOST` - gRPC server host (default: 0.0.0.0)
- `DB_USERNAME` - Database username
- `DB_PASSWORD` - Database password
- `DB_HOST` - Database host

## Development

Generate gRPC code after modifying the protobuf definition:

```bash
rake generate_grpc
```

## Architecture

MoM acts as a central coordinator for multiple Mule instances:

1. **Client Registration**: Mule instances register themselves with MoM
2. **Workflow Distribution**: MoM routes workflow requests to appropriate clients
3. **Status Monitoring**: Track execution status and client health
4. **Load Balancing**: Distribute work across available clients (future feature)

This enables scalable AI agent orchestration across multiple machines or containers.