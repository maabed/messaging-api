defmodule TalkWeb.UserSocket do
  @moduledoc false

  use Phoenix.Socket
  use Absinthe.Phoenix.Socket, schema: TalkWeb.Schema

  alias TalkWeb.Auth
  alias TalkWeb.Plug.Graphql
  alias Absinthe.Phoenix.Socket

  ## Channels
  channel "messages:*", TalkWeb.MessageChannel

  def connect(%{"authorization" => auth}, socket) do
    with "Bearer " <> token <- auth,
        {:ok, user} <- authorize(token) do
      socket_with_opts =
        socket
        |> put_options(user)
        |> assign(:user, user)

      {:ok, socket_with_opts}
    else
      _ -> :error
    end
  end

  def connect(_params, _socket), do: :error

  defp authorize(token) do
    case Auth.resource_from_token(token) do
      {:ok, {:ok, user}, _claims} -> {:ok, user}
      _ -> :unauthorized
    end
  end

  defp put_options(socket, user) do
    Socket.put_options(socket, context: Graphql.build_context(user))
  end

  # def id(_socket), do: nil
  def id(socket), do: "user_socket:#{socket.assigns.user.id}"
end
