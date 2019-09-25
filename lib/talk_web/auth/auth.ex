defmodule TalkWeb.Auth do
  @moduledoc "user authentication functions."

  use Guardian, otp_app: :talk

  alias Talk.Users
  alias Talk.Schemas.User

  @aud Application.get_env(:talk, :jwt_aud)

  def current_user(conn) do
    TalkWeb.Auth.Plug.current_resource(conn)
  end

  def subject_for_token(resource, _claims) do
    sub = to_string(resource.id)
    {:ok, sub}
  end

  def resource_from_claims(%{"sub" => id}) do
    user = Users.get_user_by_id(id)
    {:ok, user}
  end

  def resource_from_claims(_), do: {:error, :invalid_claims}

  def generate_token(%User{} = user) do
    {:ok, token, _claims} = TalkWeb.Auth.encode_and_sign(user)
    {:ok, token}
  end

  def refresh_token(token) do
    token
    |> TalkWeb.Auth.refresh()
    |> case do
      {:ok, _old, {new_token, _new_claims}} ->
        {:ok, new_token}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Guardian hooks
  def on_verify(claims, _token, _options) do
    case claims do
      %{"aud" => @aud} -> {:ok, claims}
      _ -> {:error, :invalid_audience}
    end

    case claims do
      %{"iss" => "sapien"} -> {:ok, claims}
      _ -> {:error, :invalid_issuer}
    end
  end

  def build_claims(claims, _resource, _opts) do
    claims_with_aud =
    claims
    |> Map.put("aud", @aud)

    {:ok, claims_with_aud}
  end
end
