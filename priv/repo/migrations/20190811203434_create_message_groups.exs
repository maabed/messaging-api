defmodule Talk.Repo.Migrations.CreateMessageGroups do
  @moduledoc false

  use Ecto.Migration

  def up do
    create table(:message_groups) do
      add :message_id, references(:messages), null: false
      add :group_id, references(:groups), null: false

      timestamps()
    end

    create unique_index(:message_groups, [:message_id, :group_id])
  end

  def down do
    drop table(:message_groups)
  end
end
