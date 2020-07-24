defmodule TalkWeb.HealthChecks do
  @moduledoc "HealthChecks is responsible for checking of the health of the app."

  use Plug.Router
  alias Ecto.Adapters.SQL
  alias Talk.Repo

  plug(:match)
  plug(:dispatch)

  get "/" do
    case SQL.query!(Repo, "SELECT 1") do
      %{num_rows: 1, rows: [[1]]} -> send_resp(conn, 200, "ok")
      error -> {:error, "#{Kernel.inspect(error)}"}
    end
  end
end
