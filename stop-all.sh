#!/bin/bash

# Stop all OpenTelemetry containers
echo "🛑 Stopping all OpenTelemetry containers..."

echo "Stopping Jaeger stack..."
cd Jaeger/ 2>/dev/null && ./otel-jaeger-diagnostics.sh stop_jaeger 2>/dev/null
cd ..

echo "Stopping Tempo/Grafana stack..."
cd TempoGrafana/ 2>/dev/null && ./otel-tempo-diagnostics.sh stop_tempo 2>/dev/null
cd ..

echo "Stopping any remaining containers..."
docker stop $(docker ps -q --filter "name=otel-collector") 2>/dev/null || true
docker stop $(docker ps -q --filter "name=jaeger") 2>/dev/null || true
docker stop $(docker ps -q --filter "name=tempo") 2>/dev/null || true
docker stop $(docker ps -q --filter "name=grafana") 2>/dev/null || true
docker stop $(docker ps -q --filter "name=prometheus") 2>/dev/null || true
docker stop $(docker ps -q --filter "name=otel-collector-tempo") 2>/dev/null || true

echo ""
echo "✅ All OpenTelemetry containers stopped!"
echo "📊 Check status: docker ps"
