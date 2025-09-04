# OpenTelemetry Diagnostics Toolkit

A comprehensive bash script for diagnosing OpenTelemetry setup, OTLP collector, Jaeger integration, and trace data flow.

## Quick Start

```bash
# Make the script executable (if not already)
chmod +x /home/julianguarin/Intelepeer/otel-tools/otel-diagnostics.sh

# Run a comprehensive health check
./otel-diagnostics.sh health_check

# Show all available functions
./otel-diagnostics.sh help
```

## Key Functions

### Basic Diagnostics
- **`health_check`** - Comprehensive system health check (recommended first step)
- **`check_containers`** - Verify Docker containers are running
- **`check_otlp_connectivity`** - Test OTLP and Jaeger endpoint connectivity
- **`check_collector_logs`** - View OpenTelemetry collector logs

### Trace Analysis
- **`list_jaeger_services`** - List all services sending traces to Jaeger
- **`get_recent_traces [service]`** - Get recent traces for a service
- **`get_trace_details <trace_id>`** - Detailed analysis of a specific trace
- **`monitor_traces [service]`** - Real-time trace monitoring

### Service-Specific Queries
- **`query_all_services [limit]`** - Query recent traces for all services at once
- **`query_by_operation <service> <operation> [limit]`** - Find traces by specific operation name
- **`get_service_stats [service] [hours]`** - Detailed statistics and analysis for a service
- **`compare_services`** - Performance comparison table across all services

### Sample Applications
- **`run_billing_sample`** - Run the billing session sample to generate test traces

## Common Usage Patterns

### Initial Setup Verification
```bash
# Check if everything is working
./otel-diagnostics.sh health_check

# View recent traces from billing service
./otel-diagnostics.sh get_recent_traces billing-service

# Generate new test traces
./otel-diagnostics.sh run_billing_sample
```

### Troubleshooting
```bash
# Check container status
./otel-diagnostics.sh check_containers

# View collector logs for errors
./otel-diagnostics.sh check_collector_logs 100

# Test connectivity
./otel-diagnostics.sh check_otlp_connectivity
```

### Trace Analysis
```bash
# List available services
./otel-diagnostics.sh list_jaeger_services

# Query all services at once
./otel-diagnostics.sh query_all_services 3

# Get recent traces for specific service
./otel-diagnostics.sh get_recent_traces billing-service 5

# Find traces by operation name
./otel-diagnostics.sh query_by_operation billing-service process-payment-000001 5

# Get detailed service statistics
./otel-diagnostics.sh get_service_stats billing-service 12

# Compare performance across services
./otel-diagnostics.sh compare_services

# Analyze specific trace (replace with actual trace ID)
./otel-diagnostics.sh get_trace_details f8691ebe008a7aaf14e458f139802b6b

# Monitor traces in real-time
./otel-diagnostics.sh monitor_traces billing-service 3
```

## Dependencies

The script requires these tools:
- **docker** - For container management
- **curl** - For API calls
- **jq** - For JSON processing
- **nc** (netcat) - For port testing

Install missing dependencies:
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install docker.io curl jq netcat-openbsd

# Or check what's missing
./otel-diagnostics.sh check_dependencies
```

## Expected Infrastructure

The script assumes this OpenTelemetry stack:
- **OpenTelemetry Collector** container named `otel-collector`
- **Jaeger** container named `jaeger`
- **OTLP HTTP** endpoint on port `4318`
- **OTLP GRPC** endpoint on port `4317`
- **Jaeger UI** on port `16686`

## Output Examples

### Health Check
```
========================================
OpenTelemetry Stack Health Check
========================================

[SUCCESS] All dependencies are available
[SUCCESS] OpenTelemetry Collector is running
[SUCCESS] Jaeger is running
[SUCCESS] OTLP HTTP endpoint is accessible
[SUCCESS] Jaeger UI is accessible
[SUCCESS] Available services in Jaeger:
  • billing-service
  • jaeger-all-in-one

✅ OpenTelemetry stack is healthy!
```

### Recent Traces
```
========================================
Getting Recent Traces for Service: billing-service
========================================

[SUCCESS] Found 3 traces for service 'billing-service'

TraceID: f8691ebe008a7aaf14e458f139802b6b
Spans: 7
Duration: 425950μs
Start Time: 2025-01-04 17:02:28
Operations: session-start-000000, process-payment-000001, payment-gateway-call-000002, add-usage-charge-000003, session-end-000004, generate-bill-000005, billable-session-sess-001-session_root
---
```

## Integration with Existing Workflow

This diagnostic script complements your existing OpenTelemetry setup by providing:

1. **Quick Health Checks** - Verify everything is working before running applications
2. **Trace Verification** - Confirm traces are being generated and stored correctly
3. **Troubleshooting** - Identify issues with collector, Jaeger, or connectivity
4. **Development Support** - Monitor traces during development and testing

## Customization

You can modify the script configuration at the top:
```bash
OTLP_HTTP_PORT=4318
OTLP_GRPC_PORT=4317
JAEGER_UI_PORT=16686
OTEL_COLLECTOR_NAME="otel-collector"
JAEGER_CONTAINER_NAME="jaeger"
```

## Troubleshooting Common Issues

### Container Not Running
```bash
# Check container status
./otel-diagnostics.sh check_containers

# Start containers if needed
docker start otel-collector jaeger
```

### No Traces Found
```bash
# Generate test traces
./otel-diagnostics.sh run_billing_sample

# Check collector is receiving data
./otel-diagnostics.sh check_collector_logs

# Verify services are listed
./otel-diagnostics.sh list_jaeger_services
```

### Connectivity Issues
```bash
# Test all endpoints
./otel-diagnostics.sh check_otlp_connectivity

# Check if ports are bound correctly
docker ps
```
