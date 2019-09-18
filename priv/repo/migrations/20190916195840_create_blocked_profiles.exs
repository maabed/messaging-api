defmodule Talk.Repo.Migrations.CreateBlockedProfiles do
  @moduledoc false
  use Ecto.Migration

  def up do
    create table(:blocked_profiles, primary_key: false) do
      add(
        :blocked_profile_id,
        references(:users, column: :profile_id, type: :string, on_delete: :delete_all),
        primary_key: true,
        null: false
      )

      add(
        :blocked_by_id,
        references(:users, column: :profile_id, type: :string, on_delete: :delete_all),
        primary_key: true,
        null: false
      )

      add :inserted_at, :utc_datetime_usec, default: fragment("NOW()")
      add :updated_at, :utc_datetime_usec, default: fragment("NOW()")
    end

    # execute """
    #   ALTER TABLE blocked_profiles
    #     ADD CONSTRAINT blocked_profiles_pkey PRIMARY KEY (blocked_profile_id, blocked_by_id)
    # """

    create unique_index(:blocked_profiles, [:blocked_profile_id, :blocked_by_id])

  end
  def down do
    drop table(:blocked_profiles)
  end
end
