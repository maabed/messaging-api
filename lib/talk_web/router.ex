defmodule TalkWeb.Router do
  use TalkWeb, :router
  use Plug.ErrorHandler

  @env Mix.env()

  pipeline :graphql do
    plug :accepts, ["json"]
    plug TalkWeb.Plug.AuthPipeline
  end

  pipeline :webhooks do
    plug(:accepts, ["json"])
  end

  pipeline :basic_auth do
    plug(BasicAuth, use_config: {:talk, :basic_auth})
  end


  scope "/chat-graphql" do
    pipe_through :graphql

    forward "/", Absinthe.Plug, schema: TalkWeb.Schema
  end

  scope "/graphiql" do
    if @env == :prod, do: pipe_through(:basic_auth)

    if @env == :dev do
      forward "/", Absinthe.Plug.GraphiQL,
        schema: TalkWeb.Schema,
        socket: TalkWeb.UserSocket,
        interface: :playground,
        default_url: "/chat-graphql"
    end
  end

  scope "/webhooks" do
    pipe_through :webhooks

    forward "/sync", TalkWeb.Plug.Sync
  end

  scope "/health-check" do
    forward "/", TalkWeb.HealthChecks
  end
end
