defmodule Talk.Repo.Migrations.CreateFiles do
  @moduledoc false
  use Ecto.Migration

  def up do
    create table(:files) do
      add :filename, :text, null: false
      add :content_type, :text
      add :size, :integer, null: false

      add :user_id, references(:users, type: :string), null: false

      timestamps()
    end
  end
  def down do
    drop table(:files)
  end
end
