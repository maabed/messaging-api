defmodule Talk.Repo.Migrations.CreateGroupUsers do
  @moduledoc false
  use Ecto.Migration

  def up do
    execute("CREATE TYPE group_user_role AS ENUM ('OWNER','ADMIN','MEMBER')")
    execute """
    CREATE TYPE group_user_state AS ENUM (
      'SUBSCRIBED',
      'UNSUBSCRIBED',
      'MUTED',
      'ARCHIVED'
    )
    """
    create table(:group_users) do
      add :role, :group_user_role, default: "MEMBER", null: false
      add :state, :group_user_state, default: "SUBSCRIBED", null: false
      add :bookmarked, :boolean, default: false, null: false

      add :group_id, references(:groups), null: false
      add :user_id, references(:users, type: :string), null: false

      timestamps()
    end
    create unique_index(:group_users, [:group_id, :user_id])

  end
  def down do
    drop table(:group_users)
    execute("DROP TYPE group_user_role")
    execute("DROP TYPE group_user_state")
  end
end
