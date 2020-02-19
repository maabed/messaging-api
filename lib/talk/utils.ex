defmodule Talk.Utils do
  @moduledoc false

  alias Ecto.Changeset

  @doc "Regex for validating name format."
  def name_pattern, do: ~r/^(?>[a-z0-9][a-z0-9-_.|\p{L} ]*)$/iu

  @doc "A changeset validation for name format, helps validating name, username format."
  @spec validate_format(Changeset.t(), atom()) :: Changeset.t()
  def validate_format(changeset, field) do
    Changeset.validate_format(
      changeset,
      field,
      name_pattern(),
      message: "must contain letters, numbers, underscores and dashes only"
    )
  end

  def get_path(table) do
    Path.join(Application.app_dir(:talk, "priv/sapien_db"), "#{table}.csv")
  end
end
