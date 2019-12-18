defmodule Talk.Repo.Migrations.FixIndex do
  @moduledoc false
  use Ecto.Migration

  def up do
    execute("DROP INDEX IF EXISTS message_groups_message_id_group_id_index")
    create unique_index(:message_groups, [:message_id, :group_id, :user_id])
  end

  def down do
  end
end
