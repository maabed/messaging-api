defmodule Talk.Repo.Migrations.CreateMessageReactions do
  @moduledoc false
  use Ecto.Migration

  def up do
    create table(:message_reactions) do
      add :value, :text, null: false
      add :message_id, references(:messages), null: false

      timestamps()
    end

    create unique_index(:message_reactions, [:message_id, :value])
  end

  def down do
    drop table(:message_reactions)
  end
end
