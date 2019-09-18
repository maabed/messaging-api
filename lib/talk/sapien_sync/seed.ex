defmodule Talk.SapienDB.Seed do
  @moduledoc false
  require Logger

  alias Talk.{Repo, SapienRepo}
  alias Ecto.Adapters.SQL

  @chunk_size 1_000

  def build_and_export_csv(csv_path, table, columns, export_query) do
    started = System.monotonic_time()
    SapienRepo.transaction fn ->
      SQL.stream(SapienRepo, export_query)
      |> Stream.drop(1)
      |> Stream.map(fn row ->
        Enum.map(columns, &Map.get(&1, row))
      end)
      |> CSV.encode(separator: ?|, headers: columns)
      |> Enum.into(File.stream!(csv_path, [:write, :utf8]))
    end

    ended = System.monotonic_time()
    time = System.convert_time_unit(ended - started, :native, :millisecond)
    Logger.info "#{table} exported in #{time} millisecond(s)"

    Logger.debug "sleep for 3 secs"
    :timer.sleep(:timer.seconds(3))
    import_csv(csv_path, table, columns)
  end

  def import_csv(csv_path, table, columns) do
    Logger.debug "Start importing"
    started = System.monotonic_time()

    csv_path
    |> File.stream!()
    |> Stream.drop(1)
    |> CSV.decode(separator: ?|, headers: columns)
    |> Stream.reject(fn
      {:ok, _map} -> false
      {:error, _reason} -> true
    end)
    |> Stream.map(fn {:ok, map} -> map end)
    |> Stream.chunk_every(@chunk_size)
    |> Task.async_stream(&build_and_insert_row(table, &1), max_concurrency: 4, timeout: :infinity)
    |> Stream.run

    ended = System.monotonic_time()
    time = System.convert_time_unit(ended - started, :native, :millisecond)
    Logger.info "#{table} imported in #{time} millisecond(s)"
  end

  defp build_and_insert_row(table, row) do
    chunks =
      row
      |> Enum.map(fn row ->
        row
        |> Map.update(:inserted_at, Timex.now(), &format_timestamp/1)
        |> Map.update(:updated_at, Timex.now(), &format_timestamp/1)
      end)

    upsert_rows(table, chunks)
  end

  defp upsert_rows(table, rows) do
    Repo.insert_all(table, rows, on_conflict: :nothing)
  end

  # defp has_deleted_at(row) do
  #   if !is_nil(row[:deleted_at]),
  #     do: Map.update(row, :deleted_at, nil, &format_timestamp/1),
  #     else: row
  # end

  defp format_timestamp(time) do
    if !is_nil(time) and time !== "" do
      formatted =
        time
        |> String.slice(0..-4)
        |> Timex.parse!("%Y-%m-%d %H:%M:%S.%L", :strftime)

      with usec <- DateTime.from_naive!(formatted, "Etc/UTC") do
        %DateTime{usec | microsecond: {Enum.random(100_000..999_999), 6}}
      end
    else
      nil
    end
  end
end
