# defmodule Talk.Monitoring do
#   @moduledoc """
#   Configuration for Prometheus monitoring
#   """
#   require Prometheus.Registry

#   alias Talk.Repo.Instrumenter

#   def setup do
#     Instrumenter.setup()

#     Prometheus.Registry.register_collector(:prometheus_process_collector)

#     attach_telemetry()
#   end

#   defp attach_telemetry do
#     :ok =
#       :telemetry.attach(
#         "prometheus-ecto",
#         [:talk, :repo, :query],
#         &Instrumenter.handle_event/4,
#         %{}
#       )
#   end
# end

# defmodule Talk.Repo.Instrumenter do
#   @moduledoc false
#   use Prometheus.EctoInstrumenter
# end
