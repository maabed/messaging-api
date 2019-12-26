defmodule Talk.Repo.Migrations.MessagesRenameBodyField do
  use Ecto.Migration

  def up do
    rename(table(:messages), :body, to: :content)
  end

  def down do
    rename(table(:messages), :content, to: :body)
  end
end
