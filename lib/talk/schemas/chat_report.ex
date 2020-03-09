defmodule Talk.Schemas.Report do
  @moduledoc """
  The Report schema.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Talk.Schemas.Profile

  @type t :: %__MODULE__{}
  @timestamps_opts [type: :utc_datetime_usec]
  schema "chat_reports" do
    field :type, :string, default: "spam" # spam, abuse, suspended, content policy, other
    field :status, :string, default: "active" # active, dismissed, deleted
    field :reason, :string

    # belongs_to :message, Message
    belongs_to(
      :author, Profile,
      type: :string,
      foreign_key: :author_id,
      source: :author_id
    )
    belongs_to(
      :reporter, Profile,
      type: :string,
      foreign_key: :reporter_id,
      source: :reporter_id
    )

    timestamps()
  end

  def create_changeset(struct, attrs) do
    struct
    |> cast(attrs, [:type, :reason, :author_id, :reporter_id])
    |> validate_required([:author_id, :reporter_id])
  end

  def update_changeset(struct, attrs \\ %{}) do
    struct
    |> cast(attrs, [:type, :status, :reason])
  end
end
