defmodule TalkWeb.Auth.SecretFetcher do
  @moduledoc false

  use Guardian.Token.Jwt.SecretFetcher

  def fetch_signing_secret(_module, _opts) do
    secret =
      System.get_env("JWT_PRIVATE_KEY")
      |> fetch()

    {:ok, secret}
  end

  def fetch_verifying_secret(_module, _headers, _opts) do
    secret =
      System.get_env("JWT_PUBLIC_KEY")
      |> fetch()

    {:ok, secret}
  end

  defp fetch(key) do
    key
    |> Kernel.||("")
    |> String.replace("\\n", "\n")
    |> JOSE.JWK.from_pem()
  end
end
