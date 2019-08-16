defmodule TalkWeb.Plug.Graphql do
  @moduledoc "A plug for establishing absinthe context."

  @behaviour Plug

  alias Talk.Loaders
  alias Talk.Schemas.User

  def init(opts), do: opts

  def call(conn, _) do
    user = conn.assigns[:user]
    Absinthe.Plug.put_options(conn, context: build_context(user))
  end

  def build_context(%User{} = user) do
    %{user: user, loader: build_loader(%{user: user})}
  end

  def build_context(_), do: %{}

  defp build_loader(params) do
    Dataloader.new()
    |> Dataloader.add_source(:db, Loaders.database_source(params))
  end
end
