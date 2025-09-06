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

# Quick health check for all OpenTelemetry stacks
VERSION=$(cat "$(dirname "$0")/VERSION" 2>/dev/null || echo "unknown")
echo "🏥 OpenTelemetry Stack Health Check v$VERSION"
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
