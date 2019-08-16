defmodule TalkWeb.Plug.Verify do
  @moduledoc false

  import Plug.Conn

  alias TalkWeb.Auth
  alias Talk.Schemas.User

  def fetch_user_by_token(conn, _opts \\ []) do
    case conn.assigns[:user] do
      %User{} = user ->
        assign(conn, :user, user)

      _ ->
        verify_token(conn)
    end
  end

  defp verify_token(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] ->
        case Auth.resource_from_claims(token) do
          {:ok, user} ->
            assign(conn, :user, user)

          {:error, message} ->
            body = Jason.encode!(%{message: to_string(message)})
            conn
            |> assign(:user, nil)
            |> send_resp(401, body)
        end

      _ ->
        conn
        |> assign(:user, nil)
        |> send_resp(400, "")
    end
  end
end
