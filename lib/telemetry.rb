require "opentelemetry-api"
require "opentelemetry/sdk"
require "opentelemetry/exporter/otlp"
require "opentelemetry-instrumentation-net_http"
require "opentelemetry/instrumentation/redis"

OpenTelemetry::SDK.configure do |c|
  c.use "OpenTelemetry::Instrumentation::Net::HTTP"
  c.use "OpenTelemetry::Instrumentation::Redis"
end
