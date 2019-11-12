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

    execute("DROP INDEX message_groups_message_id_group_id_index")

    create unique_index(:message_groups, [:message_id, :group_id, :user_id])
  end

  def down do
  end
end
