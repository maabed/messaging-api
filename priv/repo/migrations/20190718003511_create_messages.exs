defmodule Talk.Repo.Migrations.CreateMessages do
  @moduledoc false
  use Ecto.Migration

  def up do
    execute """
      DO $$ BEGIN
        CREATE TYPE message_type AS ENUM ('TEXT','AUDIO','VIDEO','IMAGE','DRAWING');
      EXCEPTION
        WHEN duplicate_object THEN NULL;
      END $$;
    """

    execute """
      DO $$ BEGIN
        CREATE TYPE message_status AS ENUM ('VALID','EXPIRED', 'DELETED');
      EXCEPTION
        WHEN duplicate_object THEN NULL;
      END $$;
    """

    create table(:messages) do
      add :content, :text
      add :type, :message_type, default: "TEXT", null: false
      add :status, :message_status, default: "VALID", null: false
      add :is_request, :boolean, default: false, null: false
      add :profile_id, references(:profiles, column: :_id, type: :string), null: false

      timestamps()

    end
  end
  def down do
    drop table(:messages)
    execute("DROP TYPE message_type")
    execute("DROP TYPE message_status")
  end
end
