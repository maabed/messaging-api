defmodule Talk.Repo.Migrations.CreateMessageGroups do
  @moduledoc false

  use Ecto.Migration

  def up do
    execute """
      DO $$ BEGIN
        CREATE TYPE message_read_status AS ENUM ('READ','UNREAD');
      EXCEPTION
        WHEN duplicate_object THEN NULL;
      END $$;
    """

    create table(:message_groups) do
      add :read_status, :message_read_status, null: false, default: "UNREAD"
      add :message_id, references(:messages), null: false
      add :group_id, references(:groups), null: false
      add :profile_id, references(:profiles, column: :_id, type: :string), null: false

      timestamps()
    end

    create unique_index(:message_groups, [:message_id, :group_id, :profile_id])
  end

  def down do
    drop table(:message_groups)
    execute("DROP TYPE message_read_status")
  end
end
