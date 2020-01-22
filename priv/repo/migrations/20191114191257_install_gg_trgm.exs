defmodule Talk.Repo.Migrations.InstallGgTrgm do
  @moduledoc """
  https://www.postgresql.org/docs/11/pgtrgm.html
  """
  use Ecto.Migration

  def up do
    execute("CREATE EXTENSION IF NOT EXISTS pg_trgm")
    execute("CREATE INDEX IF NOT EXISTS users_username_trgm ON profiles USING GIN (username gin_trgm_ops)")
    execute("""
      CREATE INDEX IF NOT EXISTS users_display_name_trgm ON profiles USING GIN ("displayName" gin_trgm_ops)
    """)
  end

  def down do
    execute("DROP INDEX IF EXISTS users_username_trgm")
    execute("DROP INDEX IF EXISTS users_display_name_trgm")
    execute("DROP EXTENSION IF EXISTS pg_trgm")
  end
end
