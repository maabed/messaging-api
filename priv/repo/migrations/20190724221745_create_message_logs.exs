defmodule Talk.Repo.Migrations.CreateMessageLog do
  @moduledoc false
  use Ecto.Migration

  def up do
    execute """
      DO $$ BEGIN
        CREATE TYPE log_event AS ENUM (
          'MSG_CREATED',
          'MSG_EDITED',
          'MSG_DELETED',
          'MARKED_AS_READ',
          'MARKED_AS_UNREAD',
          'SUBSCRIBED',
          'UNSUBSCRIBED'
        );
      EXCEPTION
        WHEN duplicate_object THEN NULL;
      END $$;
    """

    create table(:message_logs) do
      add :event, :log_event, null: false
      add :happen_at, :utc_datetime, null: false

      add :message_id, references(:messages), null: false
      add :profile_id, references(:profiles, column: :_id, type: :string), null: false
    end
  end

  def down do
    drop table(:message_logs)
    execute("DROP TYPE log_event")
  end
end
