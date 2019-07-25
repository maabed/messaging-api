defmodule Talk.Repo.Migrations.CreateMessageUsers do
  @moduledoc false
  use Ecto.Migration

  def up do
    execute("CREATE TYPE message_user_state AS ENUM ('READ','UNREAD')")

    create table(:message_users, primary_key: false) do
      add :id, :binary_id, null: false, primary_key: true
      add :read_at, :utc_datetime
      add :state, :message_user_state, null: false, default: "UNREAD"
      add :bookmaked, :boolean, default: false, null: false

      add :msg_id, references(:messages), null: false
      add :group_id, references(:groups), null: false
      add :user_id, references(:users, type: :string), null: false

      timestamps()
    end

    create unique_index(:message_users, [:msg_id, :group_id, :user_id])
  end

  def down do
    drop table(:message_users)
    execute("DROP TYPE message_user_state")
  end
end
