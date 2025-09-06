#!/bin/bash

# MIT License
# 
# Copyright (c) 2025 Julian Andres Guarin Reyes
# https://github.com/cppdvl/roll-and-rock-and-spans-traces
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# OpenTelemetry Jaeger Diagnostics
# Manages the Jaeger-based OpenTelemetry stack
# Usage: ./otel-jaeger-diagnostics.sh [command] [args...]

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Jaeger Configuration
OTLP_HTTP_PORT=4318
OTLP_GRPC_PORT=4317
JAEGER_UI_PORT=16686
JAEGER_API_PORT=16686
OTEL_COLLECTOR_NAME="otel-collector"
JAEGER_CONTAINER_NAME="jaeger"

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

# Start Jaeger stack
start_jaeger_stack() {
  log_header "Starting Jaeger Stack"
  
  log_info "Starting Jaeger stack with docker-compose..."
  
  if [ ! -f "docker-compose-jaeger.yml" ]; then
    log_error "docker-compose-jaeger.yml not found"
    log_info "Make sure you're in the otel-tools/Jaeger directory"
    return 1
  fi
  
  docker compose -f docker-compose-jaeger.yml up -d
  
  log_info "Waiting for services to start..."
  sleep 10
  
  # Check services
  check_jaeger_stack
  
  log_success "Jaeger stack started successfully!"
  log_info "Jaeger UI: http://localhost:$JAEGER_UI_PORT"
}

# Stop Jaeger stack
stop_jaeger_stack() {
  log_header "Stopping Jaeger Stack"
  
  if [ ! -f "docker-compose-jaeger.yml" ]; then
    log_error "docker-compose-jaeger.yml not found"
    log_info "Make sure you're in the otel-tools/Jaeger directory"
    return 1
  fi
  
  docker compose -f docker-compose-jaeger.yml down
  log_success "Jaeger stack stopped"
}

# Check Jaeger containers status
check_jaeger_containers() {
  log_header "Checking Jaeger Containers"
  
  local containers=("$OTEL_COLLECTOR_NAME" "$JAEGER_CONTAINER_NAME")
  
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
  
  log_info "All Jaeger containers:"
  docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" | grep -E "(otel-collector|jaeger)"
}

# Check Jaeger connectivity
check_jaeger_connectivity() {
  log_header "Checking Jaeger Connectivity"
  
  log_info "Testing OTLP HTTP endpoint (port $OTLP_HTTP_PORT)..."
  if curl -s -o /dev/null -w "%{http_code}" "http://localhost:$OTLP_HTTP_PORT" | grep -q "404\|405"; then
    log_success "OTLP HTTP endpoint is accessible"
  else
    log_error "OTLP HTTP endpoint is not accessible"
  fi
  
  log_info "Testing OTLP GRPC endpoint (port $OTLP_GRPC_PORT)..."
  if nc -z localhost $OTLP_GRPC_PORT; then
    log_success "OTLP GRPC port is open"
  else
    log_error "OTLP GRPC port is not accessible"
  fi
  
  log_info "Testing Jaeger UI (port $JAEGER_UI_PORT)..."
  if curl -s -o /dev/null -w "%{http_code}" "http://localhost:$JAEGER_UI_PORT" | grep -q "200"; then
    log_success "Jaeger UI is accessible"
    log_info "Jaeger UI: http://localhost:$JAEGER_UI_PORT"
  else
    log_error "Jaeger UI is not accessible"
  fi
}

# Check Jaeger stack health
check_jaeger_stack() {
  log_header "Jaeger Stack Health Check"
  
  local overall_status=0
  
  # Check containers
  if ! check_jaeger_containers; then
    overall_status=1
  fi
  
  # Check connectivity
  if ! check_jaeger_connectivity; then
    overall_status=1
  fi
  
  if [ $overall_status -eq 0 ]; then
    log_success "✅ Jaeger stack is healthy!"
    log_info "You can now send traces to Jaeger"
    log_info "Jaeger UI: http://localhost:$JAEGER_UI_PORT"
  else
    log_error "❌ Jaeger stack has issues"
    log_info "Check the errors above and fix them"
  fi
}

# Send test trace to Jaeger
send_test_trace_to_jaeger() {
  log_header "Sending Test Trace to Jaeger"
  
  log_info "Sending test trace to Jaeger via OTLP..."
  
  # Generate a test trace in OTLP format
  local trace_id=$(openssl rand -hex 16)
  local span_id=$(openssl rand -hex 8)
  local current_time_ns=$(($(date +%s) * 1000000000))
  
  local test_trace='{
    "resourceSpans": [{
      "resource": {
        "attributes": [{
          "key": "service.name",
          "value": {"stringValue": "jaeger-test-service"}
        }, {
          "key": "service.version", 
          "value": {"stringValue": "1.0.0"}
        }]
      },
      "scopeSpans": [{
        "scope": {
          "name": "jaeger-test-tracer",
          "version": "1.0.0"
        },
        "spans": [{
          "traceId": "'$trace_id'",
          "spanId": "'$span_id'",
          "name": "jaeger-test-span",
          "kind": "SPAN_KIND_INTERNAL",
          "startTimeUnixNano": "'$current_time_ns'",
          "endTimeUnixNano": "'$((current_time_ns + 100000000))'",
          "attributes": [{
            "key": "test.attribute",
            "value": {"stringValue": "jaeger-test-value"}
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
    log_success "Test trace sent to Jaeger successfully!"
    log_info "Trace ID: $trace_id"
    log_info "Wait a few seconds, then check Jaeger UI: http://localhost:$JAEGER_UI_PORT"
  else
    log_error "Failed to send test trace to Jaeger"
    log_info "Make sure the Jaeger stack is running and accessible"
  fi
}

# Run billing sample against Jaeger
run_billing_sample_jaeger() {
  log_header "Running Billing Sample with Jaeger Backend"
  
  # Check if we're in the right directory
  local sample_dir="/home/julianguarin/Intelepeer/oss-common/telemetry/examples/billingsession"
  
  if [ ! -d "$sample_dir" ]; then
    log_error "Billing sample directory not found: $sample_dir"
    return 1
  fi
  
  log_info "Running billing sample configured for Jaeger..."
  
  # Run the simplified demo with standard OTLP port
  if cd "$sample_dir" && [ -f "SimpleBillableSessionDemo" ]; then
    log_info "Running SimpleBillableSessionDemo with Jaeger endpoint..."
    
    # Use standard OTLP port for Jaeger
    OTEL_EXPORTER_OTLP_ENDPOINT="http://localhost:$OTLP_HTTP_PORT" ./SimpleBillableSessionDemo
    
    log_success "Billing sample completed successfully"
    log_info "Check traces in Jaeger UI: http://localhost:$JAEGER_UI_PORT"
  else
    log_error "SimpleBillableSessionDemo executable not found"
    log_info "Build it first in $sample_dir"
    return 1
  fi
}

# Show help
show_help() {
  echo -e "${PURPLE}OpenTelemetry Jaeger Diagnostics${NC}"
  echo -e "${PURPLE}================================${NC}"
  echo
  echo "Usage: $0 [command] [args...]"
  echo
  echo -e "${GREEN}Stack Management:${NC}"
  echo "  start_jaeger     - Start Jaeger stack"
  echo "  stop_jaeger      - Stop Jaeger stack"  
  echo "  jaeger_health    - Check Jaeger stack health"
  echo
  echo -e "${GREEN}Container Management:${NC}"
  echo "  jaeger_containers - Check Jaeger container status"
  echo "  jaeger_connectivity - Test Jaeger endpoints"
  echo
  echo -e "${GREEN}Trace Operations:${NC}"
  echo "  send_test_jaeger - Send test trace to Jaeger"
  echo
  echo -e "${GREEN}Sample Applications:${NC}"
  echo "  run_billing_jaeger - Run billing sample against Jaeger"
  echo
  echo -e "${GREEN}Legacy Commands (use main otel-diagnostics.sh):${NC}"
  echo "  ../otel-diagnostics.sh services     - List services in Jaeger"
  echo "  ../otel-diagnostics.sh traces       - Get recent traces"
  echo "  ../otel-diagnostics.sh health       - Full health check"
  echo
  echo -e "${GREEN}Examples:${NC}"
  echo "  $0 start_jaeger                     # Start the Jaeger stack"
  echo "  $0 jaeger_health                    # Check stack health"  
  echo "  $0 send_test_jaeger                 # Send test trace"
  echo "  $0 run_billing_jaeger               # Run billing sample"
  echo
  echo -e "${GREEN}UI Access:${NC}"
  echo "  Jaeger UI:  http://localhost:$JAEGER_UI_PORT"
}

# Main command dispatcher
case "${1:-help}" in
  "start_jaeger")
    start_jaeger_stack
    ;;
  "stop_jaeger")
    stop_jaeger_stack
    ;;
  "jaeger_health")
    check_jaeger_stack
    ;;
  "jaeger_containers")
    check_jaeger_containers
    ;;
  "jaeger_connectivity")
    check_jaeger_connectivity
    ;;
  "send_test_jaeger")
    send_test_trace_to_jaeger
    ;;
  "run_billing_jaeger")
    run_billing_sample_jaeger
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
