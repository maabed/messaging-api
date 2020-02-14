defmodule TalkWeb.UserSocket do
  @moduledoc false

  use Phoenix.Socket
  use Absinthe.Phoenix.Socket, schema: TalkWeb.Schema

  alias TalkWeb.Auth
  alias TalkWeb.Plug.Graphql
  alias Absinthe.Phoenix.Socket
  require Logger

  ## Channels
  channel "messages:*", TalkWeb.MessageChannel

  def connect(params, socket) do
    Logger.warn("UserSocket Connect [params] ==> #{inspect params, pretty: true}")
    Logger.warn("UserSocket Connect [authorization] ==> #{inspect Map.get(params, "authorization")}")
    with "Bearer " <> token <- Map.get(params, "authorization"),
        {:ok, user} <- authorize(token) do
      socket_with_opts =
        socket
        |> put_options(user)
        |> assign(:user, user)

      {:ok, socket_with_opts}
    else
      err ->
        Logger.error("UserSocket connect Error ==> #{inspect err, pretty: true}")
        :error
      nil ->
        {:error, "Unauthorized"}
      _ ->
        %{}
    end
  end

  defp authorize(token) do
    # Auth.debug_token(token)
    case Auth.resource_from_token(token) do
      {:ok, {:ok, user}, _claims} -> {:ok, user}
      err ->
        Logger.error("UserSocket authorize Error ==> #{inspect err, pretty: true}")
        :unauthorized
    end
  end

  defp put_options(socket, user) do
    Socket.put_options(socket, context: Graphql.build_context(user))
  end

  # def id(_socket), do: nil
  def id(socket), do: "user_socket:#{socket.assigns.user.id}"
end
