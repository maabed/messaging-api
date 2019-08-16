defmodule Talk.Repo.Migrations.CreateMessageFiles do
  @moduledoc false
  use Ecto.Migration

  def up do
    create table(:message_files) do
      add :message_id, references(:messages), null: false
      add :file_id, references(:files), null: false

      timestamps(updated_at: false)
    end

    create index(:message_files, [:message_id])
    create unique_index(:message_files, [:file_id, :message_id])
  end
  def down do
    drop table(:message_files)
  end
end
