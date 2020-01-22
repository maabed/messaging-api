# defmodule Talk.SapienDB.SeedWithCopy do
#   require Logger

#   alias Talk.{Repo, SapienRepo}
#   alias Ecto.Adapters.SQL

#   @import_users_query """
#     COPY users (
#       id,
#       profile_id,
#       display_name,
#       email,
#       username,
#       avatar,
#       inserted_at,
#       updated_at
#     ) FROM STDIN (DELIMITER '|', FORMAT csv, HEADER TRUE, NULL '', quote E'\x01')
#   """

#   def export_sapien_table_with_copy(export_query) do
#     %{num_rows: num_rows} = SQL.query!(SapienRepo, export_query)
#     Logger.info "CSV DATA:======>> #{num_rows}"
#   end

#   def import_with_copy(path, _copy_query) do
#     # copy_query = @import_users_query
#     Logger.info "Syncing users ..."
#     started = System.monotonic_time()

#     Repo.transaction(fn ->
#       Repo.query("TRUNCATE TABLE users RESTART IDENTITY CASCADE", [])
#       File.stream!(path)
#       |> Enum.into(SQL.stream(Repo, @import_users_query))
#     end)

#     ended = System.monotonic_time()
#     time = System.convert_time_unit(ended - started, :native, :millisecond)
#     Logger.info "Synchronized users in #{time} millisecond(s)"
#   end
# end
