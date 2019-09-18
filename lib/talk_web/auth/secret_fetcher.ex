defmodule TalkWeb.Auth.SecretFetcher do
  @moduledoc false

  use Guardian.Token.Jwt.SecretFetcher

  def fetch_signing_secret(_module, _opts) do
    secret =
      "private-rsa-2048.pem"
      |> fetch()

    {:ok, secret}
  end

  def fetch_verifying_secret(_module, _headers, _opts) do
    secret =
      "public-rsa-2048.pem"
      |> fetch()

    {:ok, secret}
  end

  defp fetch(key) do
    Application.app_dir(:talk, "priv/keys")
    |> Path.join(key)
    |> JOSE.JWK.from_pem_file()
  end
end
