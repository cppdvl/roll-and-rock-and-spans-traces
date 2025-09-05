#!/bin/bash

# Quick start script for Jaeger stack
echo "🚀 Starting Jaeger OpenTelemetry Stack..."

cd Jaeger/
./otel-jaeger-diagnostics.sh start_jaeger

echo ""
echo "✅ Jaeger stack started!"
echo "🌐 Jaeger UI: http://localhost:16686"
echo "📡 OTLP HTTP: http://localhost:4318"
echo "📡 OTLP gRPC: localhost:4317"
echo ""
echo "💡 Send test trace: cd Jaeger/ && ./otel-jaeger-diagnostics.sh send_test_jaeger"
