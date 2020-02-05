defmodule Talk.Repo.Migrations.FixFieldsType do
  use Ecto.Migration

  def up do
    execute "ALTER TABLE media_object ALTER COLUMN mo_for_object_id TYPE bigint USING mo_for_object_id::bigint"

    execute "ALTER TABLE groups ALTER COLUMN last_message_id TYPE text USING last_message_id::text"
    execute "ALTER TABLE groups ALTER COLUMN last_message_id TYPE bigint USING last_message_id::bigint"
  end

  def down do
    execute "ALTER TABLE media_object ALTER COLUMN mo_for_object_id TYPE text USING mo_for_object_id::text"

    execute "ALTER TABLE groups ALTER COLUMN last_message_id TYPE text USING last_message_id::text"
    execute "ALTER TABLE groups ALTER COLUMN last_message_id TYPE uuid USING last_message_id::uuid"
  end
end
