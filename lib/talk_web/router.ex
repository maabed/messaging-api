defmodule TalkWeb.Router do
  use TalkWeb, :router
  use Plug.ErrorHandler
  require Logger

  @env Mix.env()

  pipeline :graphql do
    plug :accepts, ["json"]
    plug TalkWeb.Plug.AuthPipeline
  end

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :basic_auth do
    plug(BasicAuth, use_config: {:talk, :basic_auth})
  end


  scope "/graphql" do
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
        default_url: "/graphql"
    end
  end

  scope "/health-check" do
    forward "/", TalkWeb.HealthChecks
  end
end
