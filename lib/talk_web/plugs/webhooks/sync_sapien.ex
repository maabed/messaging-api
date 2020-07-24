# defmodule TalkWeb.Plug.Sync do
#   @moduledoc """
#   Plug to handle sapien webhooks call to sync users/followers changes
#   """
#   import Plug.Conn

#   require Logger

#   alias TalkWeb.Auth
#   alias Talk.SapienDB.ApiHooks

#   def init(args), do: args

#   def call(%{method: method, params: params} = conn, _args) when method in ["POST", "PUT", "DELETE"] do
#     with :ok <- verify_token(conn),
#       {:ok, true} <- ApiHooks.perform(params) do
#       conn
#       |> put_resp_content_type("text/plain")
#       |> send_resp(200, "ok")
#     else
#       {:error, :unauthorized} ->
#         Logger.error("Sync plug => unauthorized")

#         conn
#         |> put_resp_content_type("text/plain")
#         |> send_resp(401, "Unauthorized")

#       {:error, :not_found} ->
#         Logger.error("Sync plug => Not found")

#         conn
#         |> put_resp_content_type("text/plain")
#         |> send_resp(404, "Not found")

#       {:error, reason} ->
#         Logger.error("Sync plug => Unexpected return: #{Kernel.inspect(reason)}")

#         conn
#         |> put_resp_content_type("application/json")
#         |> send_resp(500, Jason.encode!(reason))

#       _ ->
#         Logger.error("Sync plug => Bad request or unprocessable Entity")

#         conn
#         |> put_resp_content_type("text/plain")
#         |> send_resp(400, "Bad request or unprocessable entity")
#     end
#   end

#   def call(%{method: method} = conn, _args) do
#     conn
#     |> put_resp_content_type("text/plain")
#     |> send_resp(403, "#{method} not allowed")
#   end

#   defp verify_token(conn) do
#     with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
#       {:ok, claims} <- Auth.decode_and_verify(token) do
#       Logger.debug("verify_token claims: #{inspect claims}")
#       if claims["email"] === "bot@sapien.network" do
#         :ok
#       else
#         {:error, :good_try_dude}
#       end
#     else
#       {:error, reason} -> {:error, reason}
#       _ -> {:error, :unauthorized}
#     end
#   end
# end
