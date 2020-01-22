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
    fixup(:message_groups, [:inserted_at, :updated_at])
    fixup(:message_reactions, [:inserted_at, :updated_at])
    fixup(:message_logs, [:happen_at])
    fixup(:media_object, [:inserted_at, :updated_at])
    fixup(:chat_reports, [:inserted_at, :updated_at])
  end
end
