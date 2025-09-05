# OpenTelemetry Tools

A comprehensive toolkit for managing OpenTelemetry distributed tracing with multiple backend options.

## 🏗️ **Architecture**

This toolkit provides two distinct tracing backends:

### **📁 Jaeger/** - Traditional Jaeger Setup
- **Jaeger All-in-One**: Classic tracing backend
- **OpenTelemetry Collector**: OTLP → Jaeger pipeline
- **Web UI**: Simple trace viewing and search
- **Best for**: Getting started, simple deployments

### **📁 TempoGrafana/** - Modern Tempo + Grafana Setup  
- **Grafana Tempo**: High-scale distributed tracing backend
- **Grafana**: Rich visualization and dashboards
- **Prometheus**: Metrics collection and monitoring
- **TraceQL**: Advanced trace query language
- **Best for**: Production, advanced analytics, correlations

## 🚀 **Quick Start**

### **Option 1: Jaeger (Simple)**
```bash
cd Jaeger/
./otel-jaeger-diagnostics.sh start_jaeger
./otel-jaeger-diagnostics.sh jaeger_health
./otel-jaeger-diagnostics.sh send_test_jaeger

# Access Jaeger UI: http://localhost:16686
```

### **Option 2: Tempo + Grafana (Advanced)**
```bash
cd TempoGrafana/
./otel-tempo-diagnostics.sh start_tempo
./otel-tempo-diagnostics.sh tempo_health
./otel-tempo-diagnostics.sh send_test_tempo

# Access Grafana: http://localhost:3000 (admin/admin)
# Access Tempo API: http://localhost:3200
```

## 📊 **Feature Comparison**

| Feature | Jaeger | Tempo + Grafana |
|---------|---------|-----------------|
| **Setup Complexity** | Simple | Moderate |
| **Query Language** | Basic search | TraceQL |
| **Visualization** | Basic UI | Rich dashboards |
| **Scalability** | Good | Excellent |
| **Storage** | Memory/Cassandra | Object storage |
| **Correlations** | Traces only | Traces + Metrics + Logs |
| **Service Maps** | Basic | Advanced |
| **Alerting** | None | Built-in |

## 🔧 **Management Commands**

### **Root Directory Commands**
```bash
# Start/stop everything
./start-jaeger.sh           # Start Jaeger stack
./start-tempo.sh            # Start Tempo/Grafana stack
./stop-all.sh               # Stop all containers

# Quick health checks
./health-check.sh           # Check both stacks
```

### **Jaeger Commands**
```bash
cd Jaeger/
./otel-jaeger-diagnostics.sh start_jaeger
./otel-jaeger-diagnostics.sh jaeger_health
./otel-jaeger-diagnostics.sh send_test_jaeger
./otel-jaeger-diagnostics.sh run_billing_jaeger

# Legacy full diagnostics
./otel-diagnostics.sh health_check
./otel-diagnostics.sh services
./otel-diagnostics.sh traces billing-service
```

### **Tempo/Grafana Commands**
```bash
cd TempoGrafana/
./otel-tempo-diagnostics.sh start_tempo
./otel-tempo-diagnostics.sh tempo_health
./otel-tempo-diagnostics.sh query_tempo billing-service
./otel-tempo-diagnostics.sh send_test_tempo
./otel-tempo-diagnostics.sh run_billing_tempo
```

## 🌐 **UI Access Points**

### **Jaeger Setup**
- **Jaeger UI**: http://localhost:16686
- **OTLP Endpoints**: 
  - HTTP: http://localhost:4318
  - gRPC: localhost:4317

### **Tempo/Grafana Setup**
- **Grafana**: http://localhost:3000 (admin/admin)
- **Tempo API**: http://localhost:3200
- **Prometheus**: http://localhost:9090
- **OTLP Endpoints**: 
  - HTTP: http://localhost:4319
  - gRPC: localhost:4320

## 🎯 **Use Cases**

### **Development & Testing**
```bash
# Start Jaeger for quick development
cd Jaeger/ && ./otel-jaeger-diagnostics.sh start_jaeger

# Send your application traces
export OTEL_EXPORTER_OTLP_ENDPOINT="http://localhost:4318"
```

### **Production & Analytics**
```bash
# Start Tempo/Grafana for production monitoring
cd TempoGrafana/ && ./otel-tempo-diagnostics.sh start_tempo

# Configure applications for Tempo
export OTEL_EXPORTER_OTLP_ENDPOINT="http://localhost:4319"
```

### **Billing Session Tracing**
```bash
# Run billing examples against either backend
cd Jaeger/ && ./otel-jaeger-diagnostics.sh run_billing_jaeger
# OR
cd TempoGrafana/ && ./otel-tempo-diagnostics.sh run_billing_tempo
```

## 🔄 **Migration Path**

### **Jaeger → Tempo Migration**
1. **Start both stacks** (different ports)
2. **Duplicate traces** to both backends
3. **Validate Tempo setup** with test data
4. **Switch applications** to Tempo endpoints
5. **Decommission Jaeger** when ready

```bash
# Run both simultaneously
cd Jaeger/ && ./otel-jaeger-diagnostics.sh start_jaeger
cd TempoGrafana/ && ./otel-tempo-diagnostics.sh start_tempo

# Send traces to both
export OTEL_EXPORTER_OTLP_ENDPOINT="http://localhost:4318"  # Jaeger
export OTEL_EXPORTER_OTLP_ENDPOINT="http://localhost:4319"  # Tempo
```

## 🛠️ **Troubleshooting**

### **Port Conflicts**
```bash
# Check what's running
docker ps

# Stop everything
./stop-all.sh

# Start specific stack
cd Jaeger/ && ./otel-jaeger-diagnostics.sh start_jaeger
```

### **No Traces Appearing**
```bash
# Send test traces
cd Jaeger/ && ./otel-jaeger-diagnostics.sh send_test_jaeger
cd TempoGrafana/ && ./otel-tempo-diagnostics.sh send_test_tempo

# Check container logs
docker logs otel-collector
docker logs jaeger
docker logs tempo
```

### **Container Issues**
```bash
# Health checks
cd Jaeger/ && ./otel-jaeger-diagnostics.sh jaeger_health
cd TempoGrafana/ && ./otel-tempo-diagnostics.sh tempo_health

# Container status
docker ps -a
```

## 📚 **Documentation**

- **Jaeger Setup**: `Jaeger/README.md`
- **Tempo/Grafana Setup**: `TempoGrafana/README-TEMPO-GRAFANA.md`
- **OpenTelemetry Docs**: https://opentelemetry.io/docs/
- **Jaeger Docs**: https://www.jaegertracing.io/docs/
- **Tempo Docs**: https://grafana.com/docs/tempo/
- **TraceQL Reference**: https://grafana.com/docs/tempo/latest/traceql/

## 🎯 **Next Steps**

1. **Choose your backend**: Jaeger (simple) or Tempo+Grafana (advanced)
2. **Start the stack**: Follow the Quick Start guide above
3. **Send test traces**: Verify everything works
4. **Configure applications**: Point to the appropriate OTLP endpoint
5. **Monitor and analyze**: Use the UI to explore your traces

---

**🚀 Happy Tracing!**