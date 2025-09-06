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
