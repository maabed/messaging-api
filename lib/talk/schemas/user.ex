defmodule Talk.Schemas.User do
  @moduledoc """
  The User context.
  """
  use Ecto.Schema
  alias Talk.Schemas.Profile

  @type t :: %__MODULE__{}
  @primary_key {:id, :string, autogenerate: false, source: :_id}
  @timestamps_opts [type: :utc_datetime_usec]
  schema "users" do
    field :email, :string
    field :inserted_at, :utc_datetime_usec, source: :created_at

    # Hold profile data
    field :avatar, :string, virtual: true
    field :username, :string, virtual: true
    field :display_name, :string, virtual: true
    field :profile_id, :string, virtual: true


    has_one :profile, Profile
  end
end
