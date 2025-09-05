#!/bin/bash

# Quick health check for all OpenTelemetry stacks
echo "🏥 OpenTelemetry Stack Health Check"
echo "==================================="
echo ""

# Check what's running
echo "📊 Currently running containers:"
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" | grep -E "(otel|jaeger|tempo|grafana|prometheus)" || echo "No OpenTelemetry containers running"
echo ""

# Check Jaeger stack
if docker ps --format "{{.Names}}" | grep -q "jaeger"; then
  echo "🔍 Checking Jaeger stack..."
  cd Jaeger/ 2>/dev/null && ./otel-jaeger-diagnostics.sh jaeger_health 2>/dev/null
  cd ..
else
  echo "ℹ️  Jaeger stack is not running"
fi

echo ""

# Check Tempo/Grafana stack
if docker ps --format "{{.Names}}" | grep -q "tempo\|grafana"; then
  echo "🔍 Checking Tempo/Grafana stack..."
  cd TempoGrafana/ 2>/dev/null && ./otel-tempo-diagnostics.sh tempo_health 2>/dev/null
  cd ..
else
  echo "ℹ️  Tempo/Grafana stack is not running"
fi

echo ""
echo "💡 Quick start commands:"
echo "  ./start-jaeger.sh     - Start Jaeger stack"
echo "  ./start-tempo.sh      - Start Tempo/Grafana stack"
echo "  ./stop-all.sh         - Stop all containers"
