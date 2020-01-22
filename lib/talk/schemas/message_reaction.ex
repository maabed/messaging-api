defmodule Talk.Schemas.MessageReaction do
  @moduledoc """
  The MessageReactions schema.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Talk.Schemas.Message
  alias Talk.Schemas.Profile

  @type t :: %__MODULE__{}
  @timestamps_opts [type: :utc_datetime_usec]
  schema "message_reactions" do
    field :value, :string, read_after_writes: true

    belongs_to :profile, Profile, type: :string
    belongs_to :message, Message

    timestamps()
  end

  @doc false
  def create_changeset(struct, attrs \\ %{}) do
    struct
    |> cast(attrs, [:profile_id, :message_id, :value])
    |> validate_required([:value])
    |> validate_length(:value, min: 1, max: 16)
  end
end
