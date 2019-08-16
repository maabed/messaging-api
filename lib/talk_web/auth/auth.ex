defmodule TalkWeb.Auth do
  @moduledoc "user authentication functions."

  use Guardian, otp_app: :talk

  alias Talk.Repo
  alias Talk.Schemas.User

  def current_user(conn) do
    TalkWeb.Auth.Plug.current_resource(conn)
  end

  def subject_for_token(resource, _claims) do
    sub = to_string(resource.id)
    {:ok, sub}
  end

  def resource_from_claims(claims) do
    id = claims["sub"]
    user = Repo.get(User, id)
    {:ok,  user}
  end

  def generate_token(%User{} = user) do
    {:ok, token, _claims} = TalkWeb.Auth.encode_and_sign(user)
    {:ok, token}
  end

  def refresh_token(jwt) do
    {:ok, _, new_token} = TalkWeb.Auth.refresh(jwt)
    {:ok, new_token}
  end
end
