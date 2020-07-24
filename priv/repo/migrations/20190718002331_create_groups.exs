defmodule Talk.Repo.Migrations.CreateGroups do
  @moduledoc false
  use Ecto.Migration

  def up do
    # execute("CREATE EXTENSION IF NOT EXISTS citext")
    execute """
      DO $$ BEGIN
        CREATE TYPE group_status AS ENUM ('OPEN','CLOSED','DELETED');
      EXCEPTION
        WHEN duplicate_object THEN NULL;
      END $$;
    """

    create table(:groups) do
      add :name, :string
      add :description, :text
      add :picture, :text
      add :status, :group_status, default: "OPEN", null: false
      add :is_private, :boolean, default: true, null: false
      add :last_message_id, :binary_id
      add :profile_id, references(:profiles, type: :string, column: :_id), null: false

      timestamps()
    end

  end

  def down do
    drop table(:groups)
    execute("DROP TYPE group_status")
  end
end
