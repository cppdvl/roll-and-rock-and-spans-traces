# OpenTelemetry Tempo + Grafana Integration

This extends the existing otel-tools with **Grafana Tempo** and **Grafana** support for advanced distributed tracing visualization and analysis.

## 🎯 **What This Adds**

- **Grafana Tempo**: High-scale distributed tracing backend
- **Grafana**: Rich visualization and dashboards for traces  
- **Prometheus**: Metrics collection and monitoring
- **OpenTelemetry Collector**: Configured for Tempo backend
- **Pre-built Dashboards**: Ready-to-use billing session tracing dashboards

## 🚀 **Quick Start**

### 1. Start the Tempo/Grafana Stack
```bash
# Start all services (Tempo, Grafana, Prometheus, OTel Collector)
./otel-tempo-diagnostics.sh start_tempo

# Check everything is healthy
./otel-tempo-diagnostics.sh tempo_health
```

### 2. Access the UIs
- **Grafana**: http://localhost:3000 (admin/admin)
- **Tempo API**: http://localhost:3200  
- **Prometheus**: http://localhost:9090

### 3. Send Test Traces
```bash
# Send a test trace to verify connectivity
./otel-tempo-diagnostics.sh send_test_tempo

# Run the billing sample against Tempo
./otel-tempo-diagnostics.sh run_billing_tempo
```

### 4. View Traces in Grafana
1. Open http://localhost:3000 (admin/admin)
2. Go to **Explore** → Select **Tempo** datasource
3. Use TraceQL queries like: `{service.name="billing-service"}`
4. Or browse the **OpenTelemetry Billing Session Tracing** dashboard

## 📊 **Features**

### **Tempo Backend**
- **High Performance**: Handles millions of spans per second
- **Cost Effective**: Object storage backend (local for development)
- **TraceQL**: Powerful trace query language
- **Service Maps**: Automatic service dependency visualization

### **Grafana Integration**
- **Rich Visualization**: Timeline views, span details, service maps
- **TraceQL Editor**: Query traces with advanced search
- **Correlations**: Link traces to logs and metrics
- **Dashboards**: Pre-built billing session monitoring

### **Pre-built Dashboards**
- **Billing Service Overview**: Service health and performance
- **Session Tracing**: Individual customer session analysis  
- **Payment Operations**: Payment gateway performance
- **Error Analysis**: Failed operations and timeouts

## 🔧 **Configuration**

### **Ports Used**
- **3000**: Grafana UI
- **3200**: Tempo HTTP API
- **4319**: OTLP HTTP (Tempo collector)
- **4320**: OTLP gRPC (Tempo collector)  
- **9090**: Prometheus UI
- **8890**: OTel Collector metrics

### **OTLP Endpoints**
```bash
# Send traces to Tempo via collector
export OTEL_EXPORTER_OTLP_ENDPOINT="http://localhost:4319"

# Or directly to Tempo  
export OTEL_EXPORTER_OTLP_ENDPOINT="http://localhost:4318"
```

## 📈 **Usage Examples**

### **Query Recent Traces**
```bash
# Get recent billing service traces
./otel-tempo-diagnostics.sh query_tempo billing-service 10

# Get specific trace details
./otel-tempo-diagnostics.sh get_tempo_trace <trace_id>
```

### **TraceQL Queries in Grafana**
```traceql
# Find all billing sessions for a customer
{resource.customer.id="customer-alice"}

# Find slow payment operations (>100ms)
{service.name="billing-service" && name="process-payment"} | select(duration > 100ms)

# Find failed payment gateway calls
{service.name="billing-service" && name="payment-gateway-call" && status=error}

# Session analysis with costs
{resource.session.id=~"sess-.*"} | select(resource.session.total_cost, duration)
```

### **Service Map Analysis**
1. Go to **Grafana** → **Explore** → **Tempo**
2. Query: `{service.name="billing-service"}`  
3. Click **Service Map** tab
4. Visualize service dependencies and call patterns

## 🔍 **Monitoring & Observability**

### **Built-in Metrics**
- **Span Metrics**: Automatically generated from traces
- **Service Performance**: Request rates, latency percentiles  
- **Error Rates**: Failed operations and timeouts
- **Resource Usage**: Memory, CPU, storage metrics

### **Alerting** (Optional)
```bash
# Add alerting rules to prometheus.yml
- alert: HighPaymentLatency
  expr: histogram_quantile(0.95, tempo_spanmetrics_latency_bucket{span_name="process-payment"}) > 1000
  for: 2m
  labels:
    severity: warning
  annotations:
    summary: "High payment processing latency detected"
```

## 🛠️ **Advanced Configuration**

### **Storage Backend**
```yaml
# tempo-config.yaml - Switch to object storage
storage:
  trace:
    backend: s3  # or gcs, azure
    s3:
      bucket: tempo-traces
      endpoint: s3.amazonaws.com
```

### **Retention Policy**
```yaml
# tempo-config.yaml - Configure retention
compactor:
  compaction:
    block_retention: 24h      # Keep traces for 24 hours
    compacted_block_retention: 1h
```

### **Scaling**
```yaml
# Scale Tempo components
services:
  tempo-distributor:
    replicas: 3
  tempo-ingester:  
    replicas: 2
  tempo-querier:
    replicas: 2
```

## 🔧 **Troubleshooting**

### **Common Issues**

#### **No Traces Appearing**
```bash
# Check Tempo health
./otel-tempo-diagnostics.sh tempo_health

# Check collector logs
docker logs otel-collector-tempo

# Send test trace
./otel-tempo-diagnostics.sh send_test_tempo
```

#### **Grafana Can't Connect to Tempo**
```bash
# Check Tempo API
curl http://localhost:3200/ready

# Check Grafana datasource config
# Go to Grafana → Configuration → Data Sources → Tempo
# URL should be: http://tempo:3200
```

#### **High Memory Usage**
```yaml
# Reduce memory usage in tempo-config.yaml
ingester:
  max_block_bytes: 500_000      # Reduce from 1_000_000
  max_block_duration: 2m        # Reduce from 5m
```

## 🔄 **Integration with Existing Setup**

### **Coexistence with Jaeger**
- Tempo stack uses different ports (4319/4320 vs 4317/4318)
- Both can run simultaneously  
- Applications can send to both backends
- Gradual migration path available

### **Switching Applications**
```bash
# Current (Jaeger)
export OTEL_EXPORTER_OTLP_ENDPOINT="http://localhost:4318"

# New (Tempo)  
export OTEL_EXPORTER_OTLP_ENDPOINT="http://localhost:4319"
```

## 📚 **Documentation Links**

- [Grafana Tempo Documentation](https://grafana.com/docs/tempo/)
- [TraceQL Query Language](https://grafana.com/docs/tempo/latest/traceql/)
- [Grafana Tracing Guide](https://grafana.com/docs/grafana/latest/datasources/tempo/)
- [OpenTelemetry Collector](https://opentelemetry.io/docs/collector/)

## 🎯 **Next Steps**

1. **Start the stack**: `./otel-tempo-diagnostics.sh start_tempo`
2. **Send test data**: `./otel-tempo-diagnostics.sh send_test_tempo`  
3. **Explore in Grafana**: http://localhost:3000
4. **Run billing sample**: `./otel-tempo-diagnostics.sh run_billing_tempo`
5. **Create custom dashboards** for your specific use cases

---

**🎉 You now have enterprise-grade distributed tracing with Tempo and Grafana!**
