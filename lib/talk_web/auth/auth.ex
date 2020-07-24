defmodule TalkWeb.Auth do
  @moduledoc "user authentication functions."

  use Guardian, otp_app: :talk

  alias Talk.Users
  alias Talk.Schemas.User
  require Logger

  # @aud Application.get_env(:talk, :jwt_aud)

  def current_user(conn) do
    TalkWeb.Auth.Plug.current_resource(conn)
  end

  def subject_for_token(resource, _claims) do
    sub = to_string(resource.id)
    {:ok, sub}
  end

  def resource_from_claims(%{"sub" => sub}) do
    user = Users.get_user_by_id(sub)
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

  def debug_token(token) do
    Logger.warn("debug_token [token] ==> #{inspect token}")
    jwk_decode = System.get_env("JWT_PRIVATE_KEY") |> Base.decode64!() |> JOSE.JWK.from_pem() |> JOSE.JWK.to_map
    jwk_url_decode = System.get_env("JWT_PRIVATE_KEY") |> Base.url_decode64!(padding: false) |> JOSE.JWK.from_pem() |> JOSE.JWK.to_map()
    {verified, _, _} = JOSE.JWT.verify_strict(jwk_decode, ["RS256"], token)
    {url_verified, _, _} = JOSE.JWT.verify_strict(jwk_url_decode, ["RS256"], token)
    Logger.warn "debug_token JOSE verified ==> #{inspect verified}"
    Logger.warn "debug_token JOSE url_verified ==> #{inspect url_verified}"

    with {:ok, claims} <- TalkWeb.Auth.decode_and_verify(token) do
      Logger.debug("debug_token [claims] #{inspect claims, pretty: true}")
    else
      {:error, reason} ->
          Logger.debug("debug_token [ERROR] #{inspect reason, pretty: true}")
        {:error, reason}
      err ->
        Logger.debug("debug_token [other ERR] #{inspect err, pretty: true}")
        {:error, :unauthorized}
    end
  end
  # Guardian hooks
  # def on_verify(claims, _token, _options) do
    # TODO: move audience check to TalkWeb.Plug.VerifyAudience
    # case claims do
    #   %{"aud" => @aud} -> {:ok, claims}
    #   _ -> {:error, :invalid_audience}
    # end

    # case claims do
    #   %{"iss" => "sapien"} -> {:ok, claims}
    #   _ -> {:error, :invalid_issuer}
    # end
  # end

  # def build_claims(claims, _resource, _opts) do
  #   claims_with_aud =
  #   claims
  #   |> Map.put("aud", @aud)
  #   {:ok, claims_with_aud}
  # end
end
