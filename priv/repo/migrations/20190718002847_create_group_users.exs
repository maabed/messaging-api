defmodule Talk.Repo.Migrations.CreateGroupUsers do
  @moduledoc false
  use Ecto.Migration

  def up do
    execute """
      DO $$ BEGIN
        CREATE TYPE group_user_role AS ENUM ('OWNER','ADMIN','MEMBER');
      EXCEPTION
        WHEN duplicate_object THEN NULL;
      END $$;
    """

    execute """
      DO $$ BEGIN
        CREATE TYPE group_user_status AS ENUM (
          'SUBSCRIBED',
          'UNSUBSCRIBED',
          'MUTED',
          'ARCHIVED'
        );
      EXCEPTION
        WHEN duplicate_object THEN NULL;
      END $$;
    """

    create table(:group_users) do
      add :role, :group_user_role, default: "MEMBER", null: false
      add :status, :group_user_status, default: "SUBSCRIBED", null: false
      add :bookmarked, :boolean, default: false, null: false
      add :group_id, references(:groups), null: false
      add :profile_id, references(:profiles, column: :_id, type: :string), null: false

      timestamps()
    end
    create unique_index(:group_users, [:group_id, :profile_id])

  end
  def down do
    drop table(:group_users)
    execute("DROP TYPE group_user_role")
    execute("DROP TYPE group_user_status")
  end
end
