# defmodule TalkWeb.Monitoring do
#   @moduledoc """
#   Configuration for Prometheus monitoring
#   """

#   require Prometheus.Registry

#   alias TalkWeb.{
#     # Endpoint,
#     PlugPipelineInstrumenter,
#     PlugExporter,
#     GQLCollector
#   }

#   def setup do
#     # Endpoint.PhoenixInstrumenter.setup()
#     PlugPipelineInstrumenter.setup()
#     PlugExporter.setup()
#     GQLCollector.setup()

#     Prometheus.Registry.register_collector(:prometheus_process_collector)
#   end
# end

# defmodule TalkWeb.PlugPipelineInstrumenter do
#   @moduledoc false
#   use Prometheus.PlugPipelineInstrumenter
# end

# # defmodule TalkWeb.Endpoint.PhoenixInstrumenter do
# #   @moduledoc false
# #   use Prometheus.PhoenixInstrumenter
# # end

# defmodule TalkWeb.PlugExporter do
#   @moduledoc false
#   use Prometheus.PlugExporter
# end
