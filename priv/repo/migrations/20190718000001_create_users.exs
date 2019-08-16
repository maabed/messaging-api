defmodule Talk.Repo.Migrations.CreateSapienUserSchema do
  @moduledoc """
  create users schema hosted on sapien backend
  id refers to profile_id
  """
  use Ecto.Migration

  def up do
    execute "CREATE EXTENSION IF NOT EXISTS citext"

    create table(:users, primary_key: false) do
      add :id, :string, primary_key: true
      add :username, :citext, null: false
      add :name, :text, null: false
      add :email, :citext, null: false
      add :profile_id, :string, null: false
      add :thumbnail, :text
      add :inserted_at, :utc_datetime_usec, default: fragment("NOW()")
      add :updated_at, :utc_datetime_usec, default: fragment("NOW()")
    end

    create index(:users, [:id])
    create unique_index(:users, [:profile_id])
    create unique_index(:users, ["lower(username)"])
    create unique_index(:users, ["lower(email)"])
  end

  def down do
    drop table(:users)
  end
end
