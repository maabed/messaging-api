defmodule Talk.Repo.Migrations.UpdateTimestamps do
  @moduledoc false

  use Ecto.Migration

  defp fixup(table, columns) do
    alter table(table) do
      for column <- columns do
        modify column, :utc_datetime_usec, default: fragment("NOW()")
      end
    end
  end

  def change do
    fixup(:groups, [:inserted_at, :updated_at])

    fixup(:group_users, [:inserted_at, :updated_at])

    fixup(:messages, [:inserted_at, :updated_at])

    fixup(:message_users, [:inserted_at, :updated_at])

    fixup(:files, [:inserted_at, :updated_at])

    fixup(:message_files, [:inserted_at])

    fixup(:user_log, [:happen_at])
  end
end
