defmodule Talk.Repo.Migrations.CreateGroups do
  @moduledoc false
  use Ecto.Migration

  def up do
    execute("CREATE TYPE group_state AS ENUM ('OPEN','CLOSED','DELETED')")

    create table(:groups) do
      add :name, :string
      add :description, :text
      add :picture, :text
      add :state, :group_state, default: "OPEN", null: false
      add :is_private, :boolean, default: true, null: false
      add :last_message_id, :binary_id

      add :user_id, references(:users, type: :string), null: false

      timestamps()
    end

  end

  def down do
    drop table(:groups)
    execute("DROP TYPE group_state")
  end
end
