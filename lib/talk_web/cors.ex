defmodule TalkWeb.CORS do
  @moduledoc false

  # use Corsica.Router,
  #   origins: ["http://localhost:3000", ~r{^https?://(.*\.?)sapien\.network$}],
  #   allow_headers: ~w(Accept Content-Type authorization Origin, user-agent),
  #   allow_methods: ["HEAD", "GET"],
  #   log: [rejected: :error],
  #   max_age: 3600

  def check_origin(origin) do
    case Application.get_env(:talk, :allowed_origins) do
      "*" -> true

      origins -> origin in origins
    end
  end
end

