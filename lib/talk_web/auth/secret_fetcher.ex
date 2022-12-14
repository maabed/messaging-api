defmodule TalkWeb.Auth.SecretFetcher do
  @moduledoc false

  use Guardian.Token.Jwt.SecretFetcher
  require Logger

  def fetch_signing_secret(_module, _opts) do
    secret =
      fetch()
      |> JOSE.JWK.to_map
      |> elem(1)

    {:ok, secret}
  end

  def fetch_verifying_secret(_module, _headers, _opts) do
    secret =
      fetch()
      |> JOSE.JWK.to_public()

    {:ok, secret}
  end

  defp fetch() do
    case System.get_env("JWT_PRIVATE_KEY") do
      nil ->
        raise ArgumentError, "private key not set in config!"
      key ->
        case Base.url_decode64!(key, padding: false) do
          value when is_binary(value) ->
            JOSE.JWK.from_pem(value)
          :error ->
            Logger.error("invalid private key format! [JWT_PRIVATE_KEY]")
            raise ArgumentError, "invalid private key format!"
        end
    end
  end
end
