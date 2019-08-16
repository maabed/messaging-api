defmodule Talk.Repo.Migrations.CreateMessageUsers do
  @moduledoc false
  use Ecto.Migration

  def up do
    execute("CREATE TYPE message_user_state AS ENUM ('READ','UNREAD')")

    create table(:message_users) do
      add :state, :message_user_state, null: false, default: "UNREAD"

      add :group_id, references(:groups)
      add :message_id, references(:messages), null: false
      add :user_id, references(:users, type: :string), null: false

      timestamps()
    end

    create unique_index(:message_users, [:message_id, :user_id])
    create unique_index(:message_users, [:message_id, :group_id, :user_id])
  end

  def down do
    drop table(:message_users)
    execute("DROP TYPE message_user_state")
  end
end
