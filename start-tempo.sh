#!/bin/bash

# Quick start script for Tempo/Grafana stack
echo "🚀 Starting Tempo/Grafana OpenTelemetry Stack..."

cd TempoGrafana/
./otel-tempo-diagnostics.sh start_tempo

echo ""
echo "✅ Tempo/Grafana stack started!"
echo "🌐 Grafana UI: http://localhost:3000 (admin/admin)"
echo "🌐 Tempo API: http://localhost:3200"
echo "🌐 Prometheus: http://localhost:9090"
echo "📡 OTLP HTTP: http://localhost:4319"
echo "📡 OTLP gRPC: localhost:4320"
echo ""
echo "💡 Send test trace: cd TempoGrafana/ && ./otel-tempo-diagnostics.sh send_test_tempo"
