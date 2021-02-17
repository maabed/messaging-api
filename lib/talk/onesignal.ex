defmodule Talk.OneSignal do
  import Ecto.Query, warn: false
  alias Talk.Repo
  alias Ecto.Adapters.SQL

  @url "https://onesignal.com/api/v1/notifications"

  def post(message, player_id, opts \\ %{}) do
    HTTPoison.post(@url, to_payload(message, player_id, opts), headers())
  end

  defp headers() do
    [
      {"Content-Type", "application/json; charset=utf-8"},
      {"Authorization",
       "Basic #{Application.get_env(:talk, :onesignal_app_key)}"}
    ]
  end

  def get_player_id(user_id, is_web) do
    key = if is_web, do: "pushWeb", else: "pushMobile"
    device_type = if is_web, do: [5, 6, 7, 8, 9], else: [0, 1, 2, 3];

    sql = """
      SELECT "playerId"
      from user_devices d
        join profiles p
        on d."profileId" = p."_id"
      where d."userId" = $1
        and ("notificationSettings"->>$2)::BOOLEAN = TRUE
        and ("deviceInfo"->>'device_type')::int = any($3)
        and d."deletedAt" is NULL
    """
    SQL.query!(Repo, sql, [user_id, key, device_type])
    |> to_json()
    |> case do
      {:ok, [%{playerId: player_id}]} ->
        {:ok, player_id}
      {:ok, []} ->
        nil
    end
  end

  defp to_json(%Postgrex.Result{columns: columns, rows: rows}) do
    results =
      rows
      |> IO.inspect(pretty: true, label: "===== [rows] =====")
      |> Enum.map(fn row ->
        columns
        |> Enum.zip(row)
        |> Enum.into(%{}, fn {k, v} -> {String.to_atom(k), v} end)
      end)

    {:ok, results}
  end

  defp to_payload(message, player_id, opts) do
    %{
      :app_id => Application.get_env(:talk, :onesignal_app_id),
      :headings => %{:en => "Sapien"},
      :contents => %{:en => message},
      :include_player_ids => [player_id]
      # :excluded_segments => ['Banned Users']
    }
    |> Map.merge(opts)
    |> encode()
  end

  defp encode(payload) do
    {:ok, payload} = payload |> Jason.encode()
    payload
  end
end
