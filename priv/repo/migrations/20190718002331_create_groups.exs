defmodule Talk.Repo.Migrations.CreateGroups do
  @moduledoc false
  use Ecto.Migration

  def up do
    execute("CREATE TYPE group_state AS ENUM ('OPEN','CLOSED')")

    create table(:groups, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :description, :text
      add :picture, :text
      add :state, :group_state, default: "OPEN", null: false
      add :is_private, :boolean, default: true, null: false
      add :last_msg_id, :binary_id

      add :user_id, references(:users, type: :string), null: false

      timestamps()
    end

  end

  def down do
    drop table(:groups)
    execute("DROP TYPE group_state")
  end
end
