defmodule TalkWeb.Auth.SecretFetcher do
  @moduledoc false

  use Guardian.Token.Jwt.SecretFetcher

  def fetch_signing_secret(_module, _opts) do
    secret =
      %{
        "d" => System.get_env("GUARDIAN_D"),
        "dp" => System.get_env("GUARDIAN_DP"),
        "dq" => System.get_env("GUARDIAN_DQ"),
        "e" => "AQAB",
        "kty" => "RSA",
        "n" => System.get_env("GUARDIAN_N"),
        "p" => System.get_env("GUARDIAN_P"),
        "q" => System.get_env("GUARDIAN_Q"),
        "qi" => System.get_env("GUARDIAN_QI")
      }

    {:ok, secret}
  end

  def fetch_verifying_secret(_module, _headers, _opts) do
    secret =
      %{
        "e" => "AQAB",
        "kty" => "RSA",
        "n" => System.get_env("GUARDIAN_N")
      }

    {:ok, secret}
  end
end
