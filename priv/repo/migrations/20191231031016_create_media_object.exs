defmodule Talk.Repo.Migrations.CreateMediaObject do
  @moduledoc false
  use Ecto.Migration

  def up do
    execute """
      DO $$ BEGIN
        CREATE TYPE media_status AS ENUM ('ACTIVE', 'DELETED');
      EXCEPTION
        WHEN duplicate_object THEN NULL;
      END $$;
    """

    execute """
      DO $$ BEGIN
        CREATE TYPE media_type AS ENUM (
          'VIDEO',
          'AUDIO',
          'IMAGE',
          'DRAWING',
          'PDF',
          'DOCUMENT',
          'PRESENTATION',
          'RECORDING'
        );
      EXCEPTION
        WHEN duplicate_object THEN NULL;
      END $$;
    """

    create table(:media_object) do
      add :mo_type, :media_type, null: false
      add :mo_size, :integer
      add :mo_status, :media_status, default: "ACTIVE"
      add :mo_extension, :text
      add :mo_reference_id, :text
      add :mo_for_object_type, :text
      add :mo_for_object_id, :text
      add :mo_sequence, :integer
      add :mo_description, :text
      add :mo_start_date, :utc_datetime_usec
      add :mo_end_date, :utc_datetime_usec
      add :mo_position, :decimal, default: 0.0
      add :mo_created_by, references(:profiles, column: :_id, type: :string), null: false

      timestamps()
    end
  end

  def down do
    drop table(:media_object)
    execute("DROP TYPE media_status")
    execute("DROP TYPE media_type")
  end
end
