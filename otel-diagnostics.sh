#!/bin/bash

# OpenTelemetry Diagnostics Toolkit
# A comprehensive set of functions to diagnose OpenTelemetry setup and trace data flow
# Created to verify OTLP collector, Jaeger integration, and sample applications

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
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

# Check if required tools are available
check_dependencies() {
  log_header "Checking Dependencies"
  
  local deps=("docker" "curl" "jq")
  local missing=()
  
  for dep in "${deps[@]}"; do
    if command -v "$dep" &> /dev/null; then
      log_success "$dep is available"
    else
      log_error "$dep is not available"
      missing+=("$dep")
    fi
  done
  
  if [ ${#missing[@]} -gt 0 ]; then
    log_error "Missing dependencies: ${missing[*]}"
    log_info "Install missing dependencies and try again"
    return 1
  fi
  
  log_success "All dependencies are available"
}

# Check Docker containers status
check_containers() {
  log_header "Checking Docker Containers"
  
  log_info "Checking OpenTelemetry Collector container..."
  if docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -q "$OTEL_COLLECTOR_NAME"; then
    log_success "OpenTelemetry Collector is running"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep "$OTEL_COLLECTOR_NAME"
  else
    log_error "OpenTelemetry Collector is not running"
    log_info "Check with: docker ps -a | grep $OTEL_COLLECTOR_NAME"
  fi
  
  echo
  log_info "Checking Jaeger container..."
  if docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -q "$JAEGER_CONTAINER_NAME"; then
    log_success "Jaeger is running"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep "$JAEGER_CONTAINER_NAME"
  else
    log_error "Jaeger is not running"
    log_info "Check with: docker ps -a | grep $JAEGER_CONTAINER_NAME"
  fi
  
  echo
  log_info "All containers:"
  docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
}

# Check network connectivity to OTLP endpoints
check_otlp_connectivity() {
  log_header "Checking OTLP Connectivity"
  
  log_info "Testing OTLP HTTP endpoint (port $OTLP_HTTP_PORT)..."
  if curl -s -o /dev/null -w "%{http_code}" "http://localhost:$OTLP_HTTP_PORT/v1/traces" | grep -q "405\|200"; then
    log_success "OTLP HTTP endpoint is accessible"
  else
    log_error "OTLP HTTP endpoint is not accessible"
    log_info "Expected HTTP 405 (Method Not Allowed) for GET request to traces endpoint"
  fi
  
  log_info "Testing OTLP GRPC endpoint (port $OTLP_GRPC_PORT)..."
  if nc -z localhost "$OTLP_GRPC_PORT" 2>/dev/null; then
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

# Check OTLP collector logs
check_collector_logs() {
  log_header "Checking OpenTelemetry Collector Logs"
  
  local lines=${1:-50}
  log_info "Showing last $lines lines of collector logs..."
  
  if docker logs "$OTEL_COLLECTOR_NAME" --tail "$lines" 2>/dev/null; then
    log_success "Retrieved collector logs"
  else
    log_error "Failed to retrieve collector logs"
    log_info "Container might not be running or accessible"
  fi
}

# List available services in Jaeger
list_jaeger_services() {
  log_header "Checking Jaeger Services"
  
  log_info "Querying available services from Jaeger API..."
  
  if ! curl -s "http://localhost:$JAEGER_API_PORT/api/services" > /tmp/jaeger_services.json; then
    log_error "Failed to connect to Jaeger API"
    return 1
  fi
  
  if ! jq -e '.data' /tmp/jaeger_services.json > /dev/null 2>&1; then
    log_error "Invalid response from Jaeger API"
    cat /tmp/jaeger_services.json
    return 1
  fi
  
  local services
  services=$(jq -r '.data[]' /tmp/jaeger_services.json)
  
  if [ -n "$services" ]; then
    log_success "Available services in Jaeger:"
    echo "$services" | while read -r service; do
      echo -e "  ${CYAN}• $service${NC}"
    done
  else
    log_warning "No services found in Jaeger"
  fi
  
  rm -f /tmp/jaeger_services.json
}

# Get recent traces for a service
get_recent_traces() {
  local service_name=${1:-"billing-service"}
  local limit=${2:-10}
  
  log_header "Getting Recent Traces for Service: $service_name"
  
  log_info "Querying last $limit traces for service '$service_name'..."
  
  local api_url="http://localhost:$JAEGER_API_PORT/api/traces?service=$service_name&limit=$limit"
  
  if ! curl -s "$api_url" > /tmp/jaeger_traces.json; then
    log_error "Failed to retrieve traces from Jaeger API"
    return 1
  fi
  
  if ! jq -e '.data' /tmp/jaeger_traces.json > /dev/null 2>&1; then
    log_error "Invalid response from Jaeger API"
    cat /tmp/jaeger_traces.json
    return 1
  fi
  
  local trace_count
  trace_count=$(jq '.data | length' /tmp/jaeger_traces.json)
  
  if [ "$trace_count" -gt 0 ]; then
    log_success "Found $trace_count traces for service '$service_name'"
    echo
    
    jq -r '.data[] | "TraceID: \(.traceID)\nSpans: \(.spans | length)\nDuration: \(.spans[0].duration)μs\nStart Time: \(.spans[0].startTime / 1000 | strftime("%Y-%m-%d %H:%M:%S"))\nOperations: \([.spans[].operationName] | unique | join(", "))\n---"' /tmp/jaeger_traces.json
  else
    log_warning "No traces found for service '$service_name'"
    log_info "Make sure the service has sent traces recently"
  fi
  
  rm -f /tmp/jaeger_traces.json
}

# Get detailed trace information
get_trace_details() {
  local trace_id=$1
  
  if [ -z "$trace_id" ]; then
    log_error "Trace ID is required"
    log_info "Usage: get_trace_details <trace_id>"
    return 1
  fi
  
  log_header "Trace Details for: $trace_id"
  
  local api_url="http://localhost:$JAEGER_API_PORT/api/traces/$trace_id"
  
  if ! curl -s "$api_url" > /tmp/trace_details.json; then
    log_error "Failed to retrieve trace details"
    return 1
  fi
  
  if ! jq -e '.data[0]' /tmp/trace_details.json > /dev/null 2>&1; then
    log_error "Trace not found or invalid response"
    return 1
  fi
  
  log_success "Trace found! Analyzing spans..."
  echo
  
  # Show trace summary
  log_info "Trace Summary:"
  jq -r '.data[0] | "Service: \(.processes | to_entries[0].value.serviceName)\nTotal Spans: \(.spans | length)\nTrace Duration: \(.spans | map(.duration) | max)μs\nTrace Start: \(.spans | map(.startTime) | min / 1000 | strftime("%Y-%m-%d %H:%M:%S"))"' /tmp/trace_details.json
  
  echo
  log_info "Spans in chronological order:"
  jq -r '.data[0].spans | sort_by(.startTime) | .[] | "  \(.operationName) (\(.duration)μs)"' /tmp/trace_details.json
  
  echo
  log_info "Span attributes (tags) summary:"
  jq -r '.data[0].spans[] | select(.tags | length > 0) | "  \(.operationName):\n\(.tags[] | "    \(.key): \(.value)")\n"' /tmp/trace_details.json
  
  rm -f /tmp/trace_details.json
}

# Run the billing session sample
run_billing_sample() {
  log_header "Running Billing Session Sample"
  
  local sample_path="/home/julianguarin/Intelepeer/common/telemetry/examples/build/bin/BillableSessionSample"
  
  if [ ! -f "$sample_path" ]; then
    log_error "Billing sample not found at: $sample_path"
    log_info "Make sure the sample is built. Check: /home/julianguarin/Intelepeer/common/telemetry/examples/"
    return 1
  fi
  
  log_info "Running billing session sample..."
  log_info "This will generate 3 billing sessions with unique trace IDs"
  echo
  
  if "$sample_path"; then
    log_success "Billing sample completed successfully"
    log_info "Check traces in Jaeger UI: http://localhost:$JAEGER_UI_PORT"
    log_info "Or use: get_recent_traces billing-service"
  else
    log_error "Billing sample failed to run"
    return 1
  fi
}

# Comprehensive health check
health_check() {
  log_header "OpenTelemetry Stack Health Check"
  
  local overall_status=0
  
  log_info "Running comprehensive health check..."
  echo
  
  # Check dependencies
  if ! check_dependencies; then
    overall_status=1
  fi
  
  # Check containers
  check_containers
  
  # Check connectivity
  if ! check_otlp_connectivity; then
    overall_status=1
  fi
  
  # Check Jaeger services
  if ! list_jaeger_services; then
    overall_status=1
  fi
  
  echo
  if [ $overall_status -eq 0 ]; then
    log_success "✅ OpenTelemetry stack is healthy!"
    log_info "You can now run applications that send traces"
    log_info "Jaeger UI: http://localhost:$JAEGER_UI_PORT"
  else
    log_error "❌ OpenTelemetry stack has issues"
    log_info "Check the errors above and fix them"
  fi
  
  return $overall_status
}

# Query traces for all services
query_all_services() {
  local limit=${1:-5}
  
  log_header "Querying Traces for All Services"
  
  log_info "Getting services list..."
  if ! curl -s "http://localhost:$JAEGER_API_PORT/api/services" > /tmp/all_services.json; then
    log_error "Failed to get services list"
    return 1
  fi
  
  local services
  services=$(jq -r '.data[]' /tmp/all_services.json)
  
  if [ -z "$services" ]; then
    log_warning "No services found"
    return 1
  fi
  
  log_success "Found $(echo "$services" | wc -l) services"
  echo
  
  while IFS= read -r service; do
    log_info "Service: ${CYAN}$service${NC}"
    
    if curl -s "http://localhost:$JAEGER_API_PORT/api/traces?service=$service&limit=$limit" > /tmp/service_traces.json 2>/dev/null; then
      local trace_count
      trace_count=$(jq '.data | length' /tmp/service_traces.json 2>/dev/null || echo "0")
      
      if [ "$trace_count" -gt 0 ]; then
        echo "  Recent traces ($trace_count found):"
        jq -r ".data[] | \"    • \\(.traceID) (\\(.spans | length) spans, \\(.spans[0].duration)μs)\"" /tmp/service_traces.json 2>/dev/null | head -"$limit"
      else
        echo "    No recent traces found"
      fi
    else
      echo "    Failed to query traces"
    fi
    echo
  done <<< "$services"
  
  rm -f /tmp/all_services.json /tmp/service_traces.json
}

# Query traces by operation name
query_by_operation() {
  local service_name=${1:-"billing-service"}
  local operation_name=$2
  local limit=${3:-10}
  
  if [ -z "$operation_name" ]; then
    log_error "Operation name is required"
    log_info "Usage: query_by_operation <service> <operation> [limit]"
    return 1
  fi
  
  log_header "Querying Traces by Operation: $service_name -> $operation_name"
  
  local api_url="http://localhost:$JAEGER_API_PORT/api/traces?service=$service_name&operation=$operation_name&limit=$limit"
  
  if ! curl -s "$api_url" > /tmp/operation_traces.json; then
    log_error "Failed to query traces by operation"
    return 1
  fi
  
  local trace_count
  trace_count=$(jq '.data | length' /tmp/operation_traces.json 2>/dev/null || echo "0")
  
  if [ "$trace_count" -gt 0 ]; then
    log_success "Found $trace_count traces with operation '$operation_name'"
    echo
    
    jq -r '.data[] | "TraceID: \(.traceID)\nDuration: \(.spans[] | select(.operationName == "'"$operation_name"'") | .duration)μs\nStart Time: \(.spans[] | select(.operationName == "'"$operation_name"'") | .startTime / 1000 | strftime("%Y-%m-%d %H:%M:%S"))\nTags: \(.spans[] | select(.operationName == "'"$operation_name"'") | [.tags[] | "\(.key)=\(.value)"] | join(", "))\n---"' /tmp/operation_traces.json
  else
    log_warning "No traces found for operation '$operation_name' in service '$service_name'"
  fi
  
  rm -f /tmp/operation_traces.json
}

# Get service statistics
get_service_stats() {
  local service_name=${1:-"billing-service"}
  local hours=${2:-24}
  
  log_header "Service Statistics: $service_name (Last $hours hours)"
  
  # Calculate lookback time (Jaeger expects microseconds since epoch)
  local lookback_us=$((hours * 3600 * 1000000))
  local current_time_us=$(($(date +%s) * 1000000))
  local start_time_us=$((current_time_us - lookback_us))
  
  local api_url="http://localhost:$JAEGER_API_PORT/api/traces?service=$service_name&start=$start_time_us&end=$current_time_us&limit=1000"
  
  if ! curl -s "$api_url" > /tmp/service_stats.json; then
    log_error "Failed to query service statistics"
    return 1
  fi
  
  local total_traces
  total_traces=$(jq '.data | length' /tmp/service_stats.json 2>/dev/null || echo "0")
  
  if [ "$total_traces" -eq 0 ]; then
    log_warning "No traces found for service '$service_name' in the last $hours hours"
    rm -f /tmp/service_stats.json
    return 1
  fi
  
  log_success "Analyzing $total_traces traces..."
  echo
  
  # Calculate statistics
  log_info "Trace Statistics:"
  jq -r '
    .data | 
    {
      total_traces: length,
      total_spans: [.[].spans | length] | add,
      avg_spans_per_trace: ([.[].spans | length] | add / length | floor),
      unique_operations: [.[].spans[].operationName] | unique | length,
      avg_duration_ms: ([.[].spans | map(.duration) | max] | add / length / 1000 | floor),
      min_duration_ms: ([.[].spans | map(.duration) | max] | min / 1000 | floor),
      max_duration_ms: ([.[].spans | map(.duration) | max] | max / 1000 | floor)
    } |
    "  Total Traces: \(.total_traces)\n  Total Spans: \(.total_spans)\n  Avg Spans/Trace: \(.avg_spans_per_trace)\n  Unique Operations: \(.unique_operations)\n  Avg Duration: \(.avg_duration_ms)ms\n  Min Duration: \(.min_duration_ms)ms\n  Max Duration: \(.max_duration_ms)ms"
  ' /tmp/service_stats.json
  
  echo
  log_info "Top Operations by Frequency:"
  jq -r '.data[].spans[].operationName' /tmp/service_stats.json | sort | uniq -c | sort -rn | head -10 | while read -r count op; do
    echo "  $count × $op"
  done
  
  echo
  log_info "Error Analysis:"
  local error_count
  error_count=$(jq -r '.data[].spans[] | select(.tags[]?.key == "error" and .tags[]?.value == "true") | .operationName' /tmp/service_stats.json 2>/dev/null | wc -l)
  
  if [ "$error_count" -gt 0 ]; then
    log_warning "Found $error_count spans with errors"
    jq -r '.data[].spans[] | select(.tags[]?.key == "error" and .tags[]?.value == "true") | "  • \(.operationName) in trace \(.traceID)"' /tmp/service_stats.json 2>/dev/null | head -5
  else
    log_success "No errors found in recent traces"
  fi
  
  rm -f /tmp/service_stats.json
}

# Compare services performance
compare_services() {
  log_header "Service Performance Comparison"
  
  log_info "Getting services list..."
  if ! curl -s "http://localhost:$JAEGER_API_PORT/api/services" > /tmp/compare_services.json; then
    log_error "Failed to get services list"
    return 1
  fi
  
  local services
  services=$(jq -r '.data[]' /tmp/compare_services.json)
  
  if [ -z "$services" ]; then
    log_warning "No services found"
    return 1
  fi
  
  log_success "Comparing $(echo "$services" | wc -l) services"
  echo
  
  printf "%-25s %-10s %-15s %-15s %-15s\n" "Service" "Traces" "Avg Duration" "Min Duration" "Max Duration"
  printf "%-25s %-10s %-15s %-15s %-15s\n" "-------" "------" "------------" "------------" "------------"
  
  while IFS= read -r service; do
    if curl -s "http://localhost:$JAEGER_API_PORT/api/traces?service=$service&limit=50" > /tmp/service_perf.json 2>/dev/null; then
      local stats
      stats=$(jq -r '
        if (.data | length) > 0 then
          .data | 
          {
            count: length,
            avg_duration: ([.[].spans | map(.duration) | max] | add / length / 1000 | floor),
            min_duration: ([.[].spans | map(.duration) | max] | min / 1000 | floor),
            max_duration: ([.[].spans | map(.duration) | max] | max / 1000 | floor)
          } |
          "\(.count) \(.avg_duration)ms \(.min_duration)ms \(.max_duration)ms"
        else
          "0 0ms 0ms 0ms"
        end
      ' /tmp/service_perf.json 2>/dev/null)
      
      printf "%-25s %s\n" "$service" "$stats"
    else
      printf "%-25s %-10s %-15s %-15s %-15s\n" "$service" "ERROR" "-" "-" "-"
    fi
  done <<< "$services"
  
  rm -f /tmp/compare_services.json /tmp/service_perf.json
}

# Monitor traces in real-time
monitor_traces() {
  local service_name=${1:-"billing-service"}
  local interval=${2:-5}
  
  log_header "Real-time Trace Monitor for: $service_name"
  log_info "Monitoring traces every $interval seconds. Press Ctrl+C to stop."
  echo
  
  local last_count=0
  
  while true; do
    if curl -s "http://localhost:$JAEGER_API_PORT/api/traces?service=$service_name&limit=100" > /tmp/monitor_traces.json 2>/dev/null; then
      local current_count
      current_count=$(jq '.data | length' /tmp/monitor_traces.json 2>/dev/null || echo "0")
      
      if [ "$current_count" -gt "$last_count" ]; then
        local new_traces=$((current_count - last_count))
        log_success "$(date '+%H:%M:%S') - Found $new_traces new trace(s) (total: $current_count)"
        
        # Show details of new traces
        jq -r ".data[0:$new_traces][] | \"  TraceID: \\(.traceID) (\\(.spans | length) spans, \\(.spans[0].duration)μs)\"" /tmp/monitor_traces.json 2>/dev/null
        
        last_count=$current_count
      else
        echo -ne "\r$(date '+%H:%M:%S') - No new traces (total: $current_count)"
      fi
    else
      log_error "Failed to query traces"
    fi
    
    sleep "$interval"
  done
  
  rm -f /tmp/monitor_traces.json
}

# Get spans for a specific trace with detailed context
get_trace_spans() {
  local trace_id=$1
  
  if [ -z "$trace_id" ]; then
    log_error "Usage: get_trace_spans <trace_id>"
    return 1
  fi
  
  log_info "Fetching spans for trace: $trace_id"
  
  local response=$(curl -s "http://localhost:16686/api/traces/$trace_id")
  
  if [ $? -ne 0 ]; then
    log_error "Failed to fetch trace data"
    return 1
  fi
  
  # Check if trace exists
  local trace_count=$(echo "$response" | jq -r '.data | length')
  if [ "$trace_count" = "0" ] || [ "$trace_count" = "null" ]; then
    log_error "Trace not found: $trace_id"
    return 1
  fi
  
  echo
  echo "========================================"
  echo "Trace Spans Analysis"
  echo "========================================"
  echo "Trace ID: $trace_id"
  
  # Get trace-level info
  local trace_data=$(echo "$response" | jq -r '.data[0]')
  local spans=$(echo "$trace_data" | jq -r '.spans')
  local span_count=$(echo "$spans" | jq -r 'length')
  local processes=$(echo "$trace_data" | jq -r '.processes')
  
  echo "Total Spans: $span_count"
  echo
  
  # Iterate through each span
  for i in $(seq 0 $((span_count - 1))); do
    local span=$(echo "$spans" | jq -r ".[$i]")
    local span_id=$(echo "$span" | jq -r '.spanID')
    local operation_name=$(echo "$span" | jq -r '.operationName')
    local process_id=$(echo "$span" | jq -r '.processID')
    local parent_span_id=$(echo "$span" | jq -r '.references[0].spanID // "root"')
    local start_time=$(echo "$span" | jq -r '.startTime')
    local duration=$(echo "$span" | jq -r '.duration')
    
    # Get process info
    local service_name=$(echo "$processes" | jq -r ".[\"$process_id\"].serviceName")
    
    echo "----------------------------------------"
    echo "Span #$((i + 1)): $operation_name"
    echo "----------------------------------------"
    echo "  Span ID: $span_id"
    echo "  Parent Span ID: $parent_span_id"
    echo "  Service: $service_name"
    echo "  Start Time: $(echo "$start_time" | awk '{printf "%.3f", $1/1000000}')" ms
    echo "  Duration: $(echo "$duration" | awk '{printf "%.3f", $1/1000}')" ms
    
    # Generate W3C traceparent format: 00-<trace-id>-<span-id>-<trace-flags>
    # trace-flags is typically 01 for sampled traces
    echo "  W3C traceparent: 00-$trace_id-$span_id-01"
    
    # Get span tags/attributes
    local tags=$(echo "$span" | jq -r '.tags')
    if [ "$tags" != "null" ] && [ "$tags" != "[]" ]; then
      echo "  Tags/Attributes:"
      echo "$tags" | jq -r '.[] | "    " + .key + ": " + (.value | tostring)'
    fi
    
    # Get span logs/events
    local logs=$(echo "$span" | jq -r '.logs')
    if [ "$logs" != "null" ] && [ "$logs" != "[]" ]; then
      echo "  Events/Logs:"
      echo "$logs" | jq -r '.[] | "    @" + (.timestamp | tostring) + ": " + (.fields[] | .key + "=" + (.value | tostring)) '
    fi
    
    echo
  done
}

# Analyze trace hierarchy and relationships
analyze_trace_hierarchy() {
  local trace_id=$1
  
  if [ -z "$trace_id" ]; then
    log_error "Usage: analyze_trace_hierarchy <trace_id>"
    return 1
  fi
  
  log_info "Analyzing trace hierarchy for: $trace_id"
  
  local response=$(curl -s "http://localhost:16686/api/traces/$trace_id")
  
  if [ $? -ne 0 ]; then
    log_error "Failed to fetch trace data"
    return 1
  fi
  
  echo
  echo "========================================"
  echo "Trace Hierarchy Analysis"
  echo "========================================"
  echo "Trace ID: $trace_id"
  
  # Get spans and build hierarchy
  local spans=$(echo "$response" | jq -r '.data[0].spans')
  local span_count=$(echo "$spans" | jq -r 'length')
  
  echo "Total Spans: $span_count"
  echo
  echo "Hierarchy Tree:"
  echo "└─ Root Trace: $trace_id"
  
  # Find root spans (no parent)
  for i in $(seq 0 $((span_count - 1))); do
    local span=$(echo "$spans" | jq -r ".[$i]")
    local span_id=$(echo "$span" | jq -r '.spanID')
    local operation_name=$(echo "$span" | jq -r '.operationName')
    local references=$(echo "$span" | jq -r '.references')
    
    # Check if this is a root span (no parent references)
    local has_parent=$(echo "$references" | jq -r 'length')
    if [ "$has_parent" = "0" ] || [ "$has_parent" = "null" ]; then
      echo "   ├─ 🟢 ROOT: $operation_name ($span_id)"
      # Find children of this span
      print_children "$spans" "$span_id" "   │  "
    fi
  done
  
  echo
  echo "Span Relationships:"
  for i in $(seq 0 $((span_count - 1))); do
    local span=$(echo "$spans" | jq -r ".[$i]")
    local span_id=$(echo "$span" | jq -r '.spanID')
    local operation_name=$(echo "$span" | jq -r '.operationName')
    local parent_span_id=$(echo "$span" | jq -r '.references[0].spanID // "none"')
    
    if [ "$parent_span_id" = "none" ]; then
      echo "  🟢 $operation_name ($span_id) -> ROOT"
    else
      # Find parent operation name
      local parent_operation=$(echo "$spans" | jq -r ".[] | select(.spanID == \"$parent_span_id\") | .operationName")
      echo "  🔗 $operation_name ($span_id) -> $parent_operation ($parent_span_id)"
    fi
  done
}

# Helper function to print children spans recursively
print_children() {
  local spans=$1
  local parent_id=$2
  local prefix=$3
  local span_count=$(echo "$spans" | jq -r 'length')
  
  for i in $(seq 0 $((span_count - 1))); do
    local span=$(echo "$spans" | jq -r ".[$i]")
    local span_id=$(echo "$span" | jq -r '.spanID')
    local operation_name=$(echo "$span" | jq -r '.operationName')
    local parent_span_id=$(echo "$span" | jq -r '.references[0].spanID // ""')
    
    if [ "$parent_span_id" = "$parent_id" ]; then
      echo "$prefix├─ 🔗 $operation_name ($span_id)"
      print_children "$spans" "$span_id" "$prefix│  "
    fi
  done
}

# Get context propagation info for a trace
get_trace_context() {
  local trace_id=$1
  
  if [ -z "$trace_id" ]; then
    log_error "Usage: get_trace_context <trace_id>"
    return 1
  fi
  
  log_info "Analyzing context propagation for trace: $trace_id"
  
  local response=$(curl -s "http://localhost:16686/api/traces/$trace_id")
  
  if [ $? -ne 0 ]; then
    log_error "Failed to fetch trace data"
    return 1
  fi
  
  echo
  echo "========================================"
  echo "Context Propagation Analysis"
  echo "========================================"
  echo "Trace ID: $trace_id"
  
  local spans=$(echo "$response" | jq -r '.data[0].spans')
  local span_count=$(echo "$spans" | jq -r 'length')
  
  echo "Spans sharing this Trace ID: $span_count"
  echo
  
  # Check if all spans share the same trace ID
  local unique_traces=$(echo "$spans" | jq -r '.[].traceID' | sort -u | wc -l)
  if [ "$unique_traces" -eq 1 ]; then
    echo "✅ PASS: All spans share the same Trace ID"
  else
    echo "❌ FAIL: Spans have different Trace IDs (correlation broken)"
  fi
  
  echo
  echo "Span Context Details:"
  echo "---------------------"
  
  for i in $(seq 0 $((span_count - 1))); do
    local span=$(echo "$spans" | jq -r ".[$i]")
    local span_id=$(echo "$span" | jq -r '.spanID')
    local operation_name=$(echo "$span" | jq -r '.operationName')
    local trace_id_span=$(echo "$span" | jq -r '.traceID')
    local parent_span_id=$(echo "$span" | jq -r '.references[0].spanID // "root"')
    
    echo "Span: $operation_name"
    echo "  Trace ID: $trace_id_span"
    echo "  Span ID: $span_id"
    echo "  Parent: $parent_span_id"
    echo "  W3C traceparent: 00-$trace_id_span-$span_id-01"
    
    # Check for context-related tags
    local context_tags=$(echo "$span" | jq -r '.tags[] | select(.key | contains("context") or contains("correlation") or contains("session") or contains("baggage")) | "  " + .key + ": " + (.value | tostring)')
    if [ -n "$context_tags" ]; then
      echo "  Context Tags:"
      echo "$context_tags"
    fi
    echo
  done
}

# Generate W3C traceparent headers for all spans in a trace
get_w3c_traceparents() {
  local trace_id=$1
  
  if [ -z "$trace_id" ]; then
    log_error "Usage: get_w3c_traceparents <trace_id>"
    return 1
  fi
  
  log_info "Generating W3C traceparent headers for trace: $trace_id"
  
  local response=$(curl -s "http://localhost:16686/api/traces/$trace_id")
  
  if [ $? -ne 0 ]; then
    log_error "Failed to fetch trace data"
    return 1
  fi
  
  # Check if trace exists
  local trace_count=$(echo "$response" | jq -r '.data | length')
  if [ "$trace_count" = "0" ] || [ "$trace_count" = "null" ]; then
    log_error "Trace not found: $trace_id"
    return 1
  fi
  
  echo
  echo "========================================"
  echo "W3C Traceparent Headers"
  echo "========================================"
  echo "Trace ID: $trace_id"
  
  local spans=$(echo "$response" | jq -r '.data[0].spans')
  local span_count=$(echo "$spans" | jq -r 'length')
  
  echo "Total Spans: $span_count"
  echo
  echo "W3C traceparent format: 00-<trace-id>-<span-id>-<trace-flags>"
  echo "For HTTP headers: traceparent: 00-<trace-id>-<span-id>-01"
  echo
  
  # Generate traceparent for each span
  for i in $(seq 0 $((span_count - 1))); do
    local span=$(echo "$spans" | jq -r ".[$i]")
    local span_id=$(echo "$span" | jq -r '.spanID')
    local operation_name=$(echo "$span" | jq -r '.operationName')
    
    echo "Span: $operation_name"
    echo "  traceparent: 00-$trace_id-$span_id-01"
    echo "  HTTP Header: traceparent: 00-$trace_id-$span_id-01"
    echo "  curl example: curl -H \"traceparent: 00-$trace_id-$span_id-01\" <url>"
    echo
  done
  
  # Generate a JSON format for easy copy/paste
  echo "JSON Format for API requests:"
  echo "{"
  echo "  \"traceparent\": \"00-$trace_id-<span-id>-01\","
  echo "  \"tracestate\": \"\""
  echo "}"
  echo
}

# Show usage information
show_usage() {
  echo -e "${CYAN}OpenTelemetry Diagnostics Toolkit${NC}"
  echo -e "${CYAN}=================================${NC}"
  echo
  echo "Usage: $0 <function> [arguments]"
  echo
  echo "Available functions:"
  echo
  echo -e "${GREEN}Basic Diagnostics:${NC}"
  echo "  check_dependencies     - Check if required tools are installed"
  echo "  check_containers      - Check Docker container status"
  echo "  check_otlp_connectivity - Test OTLP and Jaeger endpoints"
  echo "  check_collector_logs [lines] - Show collector logs (default: 50 lines)"
  echo "  health_check          - Run comprehensive health check"
  echo
  echo -e "${GREEN}Jaeger Integration:${NC}"
  echo "  list_jaeger_services  - List all services in Jaeger"
  echo "  get_recent_traces [service] [limit] - Get recent traces (default: billing-service, 10)"
  echo "  get_trace_details <trace_id> - Get detailed trace information"
  echo "  monitor_traces [service] [interval] - Monitor traces in real-time"
  echo
  echo -e "${GREEN}Span & Context Analysis:${NC}"
  echo "  get_trace_spans <trace_id> - Get all spans in a trace with detailed context"
  echo "  analyze_trace_hierarchy <trace_id> - Analyze span hierarchy and relationships"
  echo "  get_trace_context <trace_id> - Analyze context propagation within a trace"
  echo "  get_w3c_traceparents <trace_id> - Generate W3C traceparent headers for HTTP requests"
  echo
  echo -e "${GREEN}Service-Specific Queries:${NC}"
  echo "  query_all_services [limit] - Query recent traces for all services"
  echo "  query_by_operation <service> <operation> [limit] - Find traces by operation name"
  echo "  get_service_stats [service] [hours] - Detailed statistics for a service"
  echo "  compare_services      - Performance comparison across all services"
  echo
  echo -e "${GREEN}Sample Applications:${NC}"
  echo "  run_billing_sample    - Run the billing session sample application"
  echo
  echo -e "${GREEN}Examples:${NC}"
  echo "  $0 health_check"
  echo "  $0 get_recent_traces billing-service 5"
  echo "  $0 get_trace_details abc123def456..."
  echo "  $0 get_trace_spans abc123def456..."
  echo "  $0 analyze_trace_hierarchy abc123def456..."
  echo "  $0 get_trace_context abc123def456..."
  echo "  $0 get_w3c_traceparents abc123def456..."
  echo "  $0 monitor_traces billing-service 3"
  echo "  $0 check_collector_logs 100"
  echo "  $0 query_all_services 3"
  echo "  $0 query_by_operation billing-service process-payment 5"
  echo "  $0 get_service_stats billing-service 12"
  echo "  $0 compare_services"
  echo
}

# Main function dispatcher
main() {
  if [ $# -eq 0 ]; then
    show_usage
    exit 0
  fi
  
  local function_name=$1
  shift
  
  case $function_name in
    "check_dependencies")
      check_dependencies
      ;;
    "check_containers")
      check_containers
      ;;
    "check_otlp_connectivity")
      check_otlp_connectivity
      ;;
    "check_collector_logs")
      check_collector_logs "$@"
      ;;
    "list_jaeger_services")
      list_jaeger_services
      ;;
    "get_recent_traces")
      get_recent_traces "$@"
      ;;
    "get_trace_details")
      get_trace_details "$@"
      ;;
    "get_trace_spans")
      get_trace_spans "$@"
      ;;
    "analyze_trace_hierarchy")
      analyze_trace_hierarchy "$@"
      ;;
    "get_trace_context")
      get_trace_context "$@"
      ;;
    "get_w3c_traceparents")
      get_w3c_traceparents "$@"
      ;;
    "run_billing_sample")
      run_billing_sample
      ;;
    "health_check")
      health_check
      ;;
    "monitor_traces")
      monitor_traces "$@"
      ;;
    "query_all_services")
      query_all_services "$@"
      ;;
    "query_by_operation")
      query_by_operation "$@"
      ;;
    "get_service_stats")
      get_service_stats "$@"
      ;;
    "compare_services")
      compare_services "$@"
      ;;
    "help"|"-h"|"--help")
      show_usage
      ;;
    *)
      log_error "Unknown function: $function_name"
      echo
      show_usage
      exit 1
      ;;
  esac
}

# Run main function with all arguments
main "$@"
