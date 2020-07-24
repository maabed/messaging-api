defmodule Talk.Repo.Migrations.CreateChatReports do
  @moduledoc false
  use Ecto.Migration

  def up do
    execute """
      DO $$ BEGIN
        CREATE TYPE enum_reports_type AS ENUM (
          'spam',
          'abuse',
          'suspended',
          'content policy',
          'other'
        );
      EXCEPTION
        WHEN duplicate_object THEN NULL;
      END $$;
    """

    execute """
      DO $$ BEGIN
        CREATE TYPE enum_reports_status AS ENUM (
          'active',
          'dismissed',
          'deleted'
        );
      EXCEPTION
        WHEN duplicate_object THEN NULL;
      END $$;
    """

    create table(:chat_reports) do
      add :type, :enum_reports_type, null: false, default: "spam"
      add :reason, :text, null: false
      add :status, :enum_reports_status, null: false, default: "active"
      add :author_id, references(:profiles, column: :_id, type: :string), null: false
      add :reporter_id, references(:profiles, column: :_id, type: :string), null: false
      add :message_id, references(:messages), null: false

      timestamps()
    end
  end

  def down do
    drop table(:chat_reports)
  end
end
