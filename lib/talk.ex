defmodule Talk do
  @moduledoc "See https://hexdocs.pm/elixir/Application.html"

  use Application

  def start(_type, _args) do
    import Supervisor.Spec
    children = [
      supervisor(Talk.Repo, []),
      supervisor(TalkWeb.Endpoint, []),
      supervisor(TalkWeb.Presence, []),
      supervisor(Absinthe.Subscription, [TalkWeb.Endpoint])
    ]

    opts = [strategy: :one_for_one, name: Talk.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    TalkWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
