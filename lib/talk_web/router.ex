defmodule TalkWeb.Router do
  use TalkWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", TalkWeb do
    pipe_through :api
  end
end
