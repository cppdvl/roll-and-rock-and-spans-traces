#!/bin/bash

# OpenTelemetry Tempo/Grafana Diagnostics Extension
# Extends the existing otel-diagnostics.sh with Tempo and Grafana support
# Usage: ./otel-tempo-diagnostics.sh [command] [args...]

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Tempo/Grafana Configuration
TEMPO_PORT=3200
GRAFANA_PORT=3000
PROMETHEUS_PORT=9090
OTLP_HTTP_PORT=4318
OTLP_GRPC_PORT=4317
TEMPO_CONTAINER_NAME="tempo"
GRAFANA_CONTAINER_NAME="grafana"
PROMETHEUS_CONTAINER_NAME="prometheus"
# Note: otel-collector-tempo removed - Tempo has built-in OTLP receivers

# Utility functions
log_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

log_header() {
  echo -e "\n${PURPLE}========================================${NC}"
  echo -e "${PURPLE}$1${NC}"
  echo -e "${PURPLE}========================================${NC}\n"
}

# Start Tempo/Grafana stack
start_tempo_stack() {
  log_header "Starting Tempo/Grafana Stack"
  
  log_info "Starting Tempo/Grafana stack with docker-compose..."
  
  if [ ! -f "docker-compose-tempo-grafana.yml" ]; then
    log_error "docker-compose-tempo-grafana.yml not found"
    log_info "Make sure you're in the otel-tools/TempoGrafana directory"
    return 1
  fi
  
  docker compose -f docker-compose-tempo-grafana.yml up -d
  
  log_info "Waiting for services to start..."
  sleep 10
  
  # Check services
  check_tempo_stack
  
  log_success "Tempo/Grafana stack started successfully!"
  log_info "Grafana UI: http://localhost:$GRAFANA_PORT (admin/admin)"
  log_info "Tempo API: http://localhost:$TEMPO_PORT"
  log_info "Prometheus: http://localhost:$PROMETHEUS_PORT"
}

# Stop Tempo/Grafana stack
stop_tempo_stack() {
  log_header "Stopping Tempo/Grafana Stack"
  
  if [ ! -f "docker-compose-tempo-grafana.yml" ]; then
    log_error "docker-compose-tempo-grafana.yml not found"
    log_info "Make sure you're in the otel-tools/TempoGrafana directory"
    return 1
  fi
  
  docker compose -f docker-compose-tempo-grafana.yml down
  log_success "Tempo/Grafana stack stopped"
}

# Check Tempo/Grafana containers status
check_tempo_containers() {
  log_header "Checking Tempo/Grafana Containers"
  
  local containers=("$TEMPO_CONTAINER_NAME" "$GRAFANA_CONTAINER_NAME" "$PROMETHEUS_CONTAINER_NAME")
  
  for container in "${containers[@]}"; do
    log_info "Checking $container container..."
    if docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -q "$container"; then
      log_success "$container is running"
      docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep "$container"
    else
      log_error "$container is not running"
      log_info "Check with: docker ps -a | grep $container"
    fi
    echo
  done
  
  log_info "All Tempo/Grafana containers:"
  docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" | grep -E "(tempo|grafana|prometheus)"
}

# Check Tempo/Grafana connectivity
check_tempo_connectivity() {
  log_header "Checking Tempo/Grafana Connectivity"
  
  log_info "Testing Tempo API (port $TEMPO_PORT)..."
  if curl -s -o /dev/null -w "%{http_code}" "http://localhost:$TEMPO_PORT/ready" | grep -q "200"; then
    log_success "Tempo API is accessible"
    log_info "Tempo API: http://localhost:$TEMPO_PORT"
  else
    log_error "Tempo API is not accessible"
  fi
  
  log_info "Testing Grafana UI (port $GRAFANA_PORT)..."
  if curl -s -o /dev/null -w "%{http_code}" "http://localhost:$GRAFANA_PORT/api/health" | grep -q "200"; then
    log_success "Grafana UI is accessible"
    log_info "Grafana UI: http://localhost:$GRAFANA_PORT (admin/admin)"
  else
    log_error "Grafana UI is not accessible"
  fi
  
  log_info "Testing Prometheus (port $PROMETHEUS_PORT)..."
  if curl -s -o /dev/null -w "%{http_code}" "http://localhost:$PROMETHEUS_PORT/-/healthy" | grep -q "200"; then
    log_success "Prometheus is accessible"
    log_info "Prometheus UI: http://localhost:$PROMETHEUS_PORT"
  else
    log_error "Prometheus is not accessible"
  fi
}

# Check Tempo/Grafana stack health
check_tempo_stack() {
  log_header "Tempo/Grafana Stack Health Check"
  
  local overall_status=0
  
  # Check containers
  if ! check_tempo_containers; then
    overall_status=1
  fi
  
  # Check connectivity
  if ! check_tempo_connectivity; then
    overall_status=1
  fi
  
  if [ $overall_status -eq 0 ]; then
    log_success "✅ Tempo/Grafana stack is healthy!"
    log_info "You can now send traces to Tempo and view them in Grafana"
    log_info "Grafana UI: http://localhost:$GRAFANA_PORT"
    log_info "Tempo API: http://localhost:$TEMPO_PORT"
  else
    log_error "❌ Tempo/Grafana stack has issues"
    log_info "Check the errors above and fix them"
  fi
}

# Query traces from Tempo
query_tempo_traces() {
  local service_name="$1"
  local limit="${2:-10}"
  
  if [ -z "$service_name" ]; then
    log_header "Available Services in Tempo"
    log_info "Getting list of available services..."
    
    if curl -s "http://localhost:$TEMPO_PORT/api/search/tag/service.name/values" > /tmp/tempo_services_full.json 2>/dev/null; then
      local service_count
      service_count=$(jq '.tagValues | length' /tmp/tempo_services_full.json)
      
      if [ "$service_count" -gt 0 ]; then
        log_success "Found $service_count services with trace data:"
        echo
        jq -r '.tagValues[] | "  • \(.)"' /tmp/tempo_services_full.json
        echo
        log_info "Usage: query_tempo <service_name> [limit]"
        log_info "Example: ./otel-tempo-diagnostics.sh query_tempo tempo-test-service"
      else
        log_warning "No services found in Tempo"
      fi
    else
      log_error "Failed to retrieve services from Tempo"
    fi
    
    rm -f /tmp/tempo_services_full.json
    return 0
  fi
  
  log_header "Querying Traces from Tempo: $service_name"
  
  log_info "Querying traces for service '$service_name' from Tempo..."
  
  # Use Tempo's search API
  local api_url="http://localhost:$TEMPO_PORT/api/search?tags=service.name=$service_name&limit=$limit"
  
  if ! curl -s "$api_url" > /tmp/tempo_traces.json; then
    log_error "Failed to retrieve traces from Tempo API"
    return 1
  fi
  
  if ! jq -e '.traces' /tmp/tempo_traces.json > /dev/null 2>&1; then
    log_error "Invalid response from Tempo API"
    cat /tmp/tempo_traces.json
    return 1
  fi
  
  local trace_count
  trace_count=$(jq '.traces | length' /tmp/tempo_traces.json)
  
  if [ "$trace_count" -gt 0 ]; then
    log_success "Found $trace_count traces for service '$service_name'"
    echo
    
    jq -r '.traces[] | "TraceID: \(.traceID)\nService: \(.rootServiceName)\nSpan: \(.rootTraceName)\nDuration: \(.durationMs)ms\nStart Time: \(.startTimeUnixNano)\n---"' /tmp/tempo_traces.json
  else
    log_warning "No traces found for service '$service_name'"
    log_info "Make sure the service has sent traces to Tempo recently"
  fi
  
  rm -f /tmp/tempo_traces.json
}

# Get trace details from Tempo
get_tempo_trace() {
  local trace_id="$1"
  
  if [ -z "$trace_id" ]; then
    log_error "Trace ID is required"
    log_info "Usage: get_tempo_trace <trace_id>"
    return 1
  fi
  
  log_header "Tempo Trace Details: $trace_id"
  
  local api_url="http://localhost:$TEMPO_PORT/api/traces/$trace_id"
  
  if ! curl -s "$api_url" > /tmp/tempo_trace_details.json; then
    log_error "Failed to retrieve trace details from Tempo"
    return 1
  fi
  
  if jq -e '.batches' /tmp/tempo_trace_details.json > /dev/null 2>&1; then
    log_success "Trace found in Tempo"
    echo
    
    # Extract trace information
    local span_count
    span_count=$(jq '[.batches[].instrumentationLibrarySpans[].spans[]] | length' /tmp/tempo_trace_details.json)
    
    local service_name
    service_name=$(jq -r '.batches[0].resource.attributes[] | select(.key=="service.name") | .value.stringValue' /tmp/tempo_trace_details.json)
    
    echo -e "${CYAN}Trace ID:${NC} $trace_id"
    echo -e "${CYAN}Service:${NC} $service_name"
    echo -e "${CYAN}Span Count:${NC} $span_count"
    echo
    
    log_info "Spans in this trace:"
    jq -r '.batches[].instrumentationLibrarySpans[].spans[] | "  • \(.name) (Duration: \((.endTimeUnixNano - .startTimeUnixNano) / 1000000)ms)"' /tmp/tempo_trace_details.json
    
    echo
    log_info "View full trace in Grafana: http://localhost:$GRAFANA_PORT/explore?orgId=1&left=%5B%22now-1h%22,%22now%22,%22Tempo%22,%7B%22query%22:%22$trace_id%22%7D%5D"
  else
    log_warning "Trace not found in Tempo"
  fi
  
  rm -f /tmp/tempo_trace_details.json
}

# Send test trace to Tempo
send_test_trace_to_tempo() {
  log_header "Sending Test Trace to Tempo"
  
  log_info "Sending test trace to Tempo via OTLP..."
  
  # Generate a test trace in OTLP format
  local trace_id=$(openssl rand -hex 16)
  local span_id=$(openssl rand -hex 8)
  local current_time_ns=$(($(date +%s) * 1000000000))
  
  local test_trace='{
    "resourceSpans": [{
      "resource": {
        "attributes": [{
          "key": "service.name",
          "value": {"stringValue": "tempo-test-service"}
        }, {
          "key": "service.version", 
          "value": {"stringValue": "1.0.0"}
        }]
      },
      "scopeSpans": [{
        "scope": {
          "name": "tempo-test-tracer",
          "version": "1.0.0"
        },
        "spans": [{
          "traceId": "'$trace_id'",
          "spanId": "'$span_id'",
          "name": "tempo-test-span",
          "kind": "SPAN_KIND_INTERNAL",
          "startTimeUnixNano": "'$current_time_ns'",
          "endTimeUnixNano": "'$((current_time_ns + 100000000))'",
          "attributes": [{
            "key": "test.attribute",
            "value": {"stringValue": "tempo-test-value"}
          }, {
            "key": "operation.type",
            "value": {"stringValue": "test"}
          }],
          "status": {
            "code": "STATUS_CODE_OK"
          }
        }]
      }]
    }]
  }'
  
  if curl -X POST "http://localhost:$OTLP_HTTP_PORT/v1/traces" \
       -H "Content-Type: application/json" \
       -d "$test_trace" > /dev/null 2>&1; then
    log_success "Test trace sent to Tempo successfully!"
    log_info "Trace ID: $trace_id"
    log_info "Wait a few seconds, then check: query_tempo_traces tempo-test-service"
    log_info "Or view in Grafana: http://localhost:$GRAFANA_PORT/explore"
  else
    log_error "Failed to send test trace to Tempo"
    log_info "Make sure the Tempo stack is running and accessible"
  fi
}

# Run billing sample against Tempo
run_billing_sample_tempo() {
  log_header "Running Billing Sample with Tempo Backend"
  
  # Check if we're in the right directory
  local sample_dir="/home/julianguarin/Intelepeer/oss-common/telemetry/examples/billingsession"
  
  if [ ! -d "$sample_dir" ]; then
    log_error "Billing sample directory not found: $sample_dir"
    return 1
  fi
  
  log_info "Running billing sample configured for Tempo..."
  
  # Run the simplified demo but configured to send to Tempo port
  if cd "$sample_dir" && [ -f "SimpleBillableSessionDemo" ]; then
    log_info "Running SimpleBillableSessionDemo with Tempo endpoint..."
    
    # Set environment variable to use Tempo's OTLP port
    OTEL_EXPORTER_OTLP_ENDPOINT="http://localhost:4319" ./SimpleBillableSessionDemo
    
    log_success "Billing sample completed successfully"
    log_info "Check traces in Grafana: http://localhost:$GRAFANA_PORT/explore"
    log_info "Or query with: query_tempo_traces billing-service"
  else
    log_error "SimpleBillableSessionDemo executable not found"
    log_info "Build it first in $sample_dir"
    return 1
  fi
}

# Show help
show_help() {
  echo -e "${PURPLE}OpenTelemetry Tempo/Grafana Diagnostics${NC}"
  echo -e "${PURPLE}=======================================${NC}"
  echo
  echo "Usage: $0 [command] [args...]"
  echo
  echo -e "${GREEN}Stack Management:${NC}"
  echo "  start_tempo     - Start Tempo/Grafana stack"
  echo "  stop_tempo      - Stop Tempo/Grafana stack"  
  echo "  tempo_health    - Check Tempo/Grafana stack health"
  echo
  echo -e "${GREEN}Container Management:${NC}"
  echo "  tempo_containers - Check Tempo/Grafana container status"
  echo "  tempo_connectivity - Test Tempo/Grafana endpoints"
  echo
  echo -e "${GREEN}Trace Operations:${NC}"
  echo "  query_tempo [service] [limit] - Query traces from Tempo (shows available services if no service specified)"
  echo "  get_tempo_trace <trace_id>    - Get detailed trace from Tempo"
  echo "  send_test_tempo              - Send test trace to Tempo"
  echo
  echo -e "${GREEN}Sample Applications:${NC}"
  echo "  run_billing_tempo - Run billing sample against Tempo"
  echo
  echo -e "${GREEN}Examples:${NC}"
  echo "  $0 start_tempo                    # Start the Tempo/Grafana stack"
  echo "  $0 tempo_health                   # Check stack health"  
  echo "  $0 query_tempo                    # List all services with data"
  echo "  $0 query_tempo tempo-test-service 5  # Get 5 recent traces for specific service"
  echo "  $0 send_test_tempo                # Send test trace"
  echo "  $0 run_billing_tempo              # Run billing sample"
  echo
  echo -e "${GREEN}UI Access:${NC}"
  echo "  Grafana:    http://localhost:$GRAFANA_PORT (admin/admin)"
  echo "  Tempo:      http://localhost:$TEMPO_PORT"
  echo "  Prometheus: http://localhost:$PROMETHEUS_PORT"
}

# Main command dispatcher
case "${1:-help}" in
  "start_tempo")
    start_tempo_stack
    ;;
  "stop_tempo")
    stop_tempo_stack
    ;;
  "tempo_health")
    check_tempo_stack
    ;;
  "tempo_containers")
    check_tempo_containers
    ;;
  "tempo_connectivity")
    check_tempo_connectivity
    ;;
  "query_tempo")
    query_tempo_traces "${2:-}" "${3:-10}"
    ;;
  "get_tempo_trace")
    if [ -z "${2:-}" ]; then
      log_error "Trace ID required"
      echo "Usage: $0 get_tempo_trace <trace_id>"
      exit 1
    fi
    get_tempo_trace "$2"
    ;;
  "send_test_tempo")
    send_test_trace_to_tempo
    ;;
  "run_billing_tempo")
    run_billing_sample_tempo
    ;;
  "help"|"--help"|"-h")
    show_help
    ;;
  *)
    log_error "Unknown command: $1"
    echo
    show_help
    exit 1
    ;;
esac
