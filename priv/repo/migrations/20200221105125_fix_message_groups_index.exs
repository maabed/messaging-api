defmodule Talk.Repo.Migrations.FixMessageGroupsIndex do
  @moduledoc false

  use Ecto.Migration

  def up do
    drop index(:message_groups, [:message_id, :group_id, :profile_id], name: :message_groups_message_id_group_id_profile_id_index)

    create unique_index(:message_groups, [:message_id, :profile_id])
  end

  def down do
    drop index(:message_groups, [:message_id, :profile_id], name: :message_groups_message_id_profile_id_index)

    create unique_index(:message_groups, [:message_id, :group_id, :profile_id])
  end
end
