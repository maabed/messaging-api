defmodule Talk.Repo.Migrations.RemoveMessageUsers do
  @moduledoc false
  use Ecto.Migration

  def up do
    drop table(:message_users)
    execute("DROP TYPE message_user_state")

    execute("CREATE TYPE message_read_state AS ENUM ('READ','UNREAD')")
    alter table(:message_groups) do
      add :read_state, :message_read_state, null: false, default: "UNREAD"
      add :user_id, references(:users, type: :string), null: false
    end
  end

  def down do
  end
end
