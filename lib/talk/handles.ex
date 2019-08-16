defmodule Talk.Handles do
  @moduledoc "helpers to validate name, username format."

  alias Ecto.Changeset

  @doc "Regex for validating name format."
  def name_pattern, do: ~r/^(?>[a-z0-9][a-z0-9-]*)$/ix

  @doc "A changeset validation for name format."
  @spec validate_format(Changeset.t(), atom()) :: Changeset.t()
  def validate_format(changeset, field) do
    Changeset.validate_format(
      changeset,
      field,
      name_pattern(),
      message: "must contain letters, numbers, and dashes only"
    )
  end
end
