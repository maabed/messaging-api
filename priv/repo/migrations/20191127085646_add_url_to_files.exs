defmodule Talk.Repo.Migrations.AddUrlToFiles do
  use Ecto.Migration

  def up do
    alter table(:files) do
      add :url, :text
    end
  end

  def down do
    alter table(:files) do
      remove :url
    end
  end
end
