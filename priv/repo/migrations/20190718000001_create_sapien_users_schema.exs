defmodule Talk.Repo.Migrations.CreateSapienUserSchema do
  @moduledoc """
  create users schema hosted on sapien backend
  id refers to profile_id
  """
  use Ecto.Migration

  def up do
    create table(:users, primary_key: false) do
      add :id, :string, primary_key: true
      add :username, :text
      add :name, :text
      add :thumbnail, :text
      add :user_id, :string
      add :inserted_at, :utc_datetime_usec, default: fragment("NOW()")
      add :updated_at, :utc_datetime_usec, default: fragment("NOW()")
    end
  end

  def down do
    drop table(:users)
  end
end
