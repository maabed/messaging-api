defmodule Talk.Repo.Migrations.RemoveMessageFromChatReports do
  @moduledoc false

  use Ecto.Migration

  def up do
    alter table(:chat_reports) do
      remove :message_id
    end
  end

  def down do
    alter table(:chat_reports) do
      add :message_id, references(:messages), null: false
    end
  end
end
