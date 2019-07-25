defmodule Talk.Repo.Migrations.AddUserLog do
  @moduledoc false
  use Ecto.Migration

  def up do
    execute """
    CREATE TYPE log_event AS ENUM (
      'MARKED_AS_READ',
      'MARKED_AS_UNREAD',
      'SUBSCRIBED',
      'UNSUBSCRIBED'
    )
    """

    create table(:user_log, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :event, :log_event, null: false
      add :happen_at, :utc_datetime, null: false

      add :msg_id, references(:messages), null: false
      add :user_id, references(:users, type: :string), null: false
    end
  end

  def down do
    drop table(:user_log)
    execute("DROP TYPE log_event")
  end
end
