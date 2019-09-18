defmodule Talk.Repo.Migrations.CreateFollower do
  @moduledoc false
  use Ecto.Migration

  def up do
    create table(:followers, primary_key: false) do
      add(
        :follower_id,
        references(:users, column: :profile_id, type: :string, on_delete: :delete_all),
        primary_key: true,
        null: false
      )

      add(
        :following_id,
        references(:users, column: :profile_id, type: :string, on_delete: :delete_all),
        primary_key: true,
        null: false
      )

      add :inserted_at, :utc_datetime_usec, default: fragment("NOW()")
      add :updated_at, :utc_datetime_usec, default: fragment("NOW()")
    end

    # execute """
    #   ALTER TABLE followers
    #     ADD CONSTRAINT followers_pkey PRIMARY KEY (following_id, follower_id)
    # """

    create unique_index(:followers, [:following_id, :follower_id])

  end
  def down do
    drop table(:followers)
  end
end
