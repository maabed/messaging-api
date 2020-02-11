defmodule TalkWeb.Auth.SecretFetcher do
  @moduledoc false

  use Guardian.Token.Jwt.SecretFetcher

  def fetch_signing_secret(_module, _opts) do
    secret =
      fetch()
      |> JOSE.JWK.to_map
      |> elem(1)

    {:ok, secret}
  end

  def fetch_verifying_secret(_module, _headers, _opts) do
    secret = fetch() |> JOSE.JWK.to_public()

    {:ok, secret}
  end

  defp fetch() do
    System.get_env("JWT_PRIVATE_KEY")
    |> Base.decode64!()
    |> JOSE.JWK.from_pem()
  end
end
