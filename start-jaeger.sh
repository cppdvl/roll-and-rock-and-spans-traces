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
