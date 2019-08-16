defmodule Talk.Repo.Migrations.CreateMessages do
  @moduledoc false
  use Ecto.Migration

  def up do
    execute("CREATE TYPE message_type AS ENUM ('TEXT','AUDIO','VIDEO','IMAGE','DRAWING')")
    execute("CREATE TYPE message_state AS ENUM ('VALID','EXPIRED', 'DELETED')")

    create table(:messages) do
      add :body, :text
      add :type, :message_type, default: "TEXT", null: false
      add :state, :message_state, default: "VALID", null: false
      add :is_request, :boolean, default: false, null: false

      add :user_id, references(:users, type: :string), null: false

      timestamps()

    end
  end
  def down do
    drop table(:messages)
    execute("DROP TYPE message_type")
    execute("DROP TYPE message_state")
  end
end
