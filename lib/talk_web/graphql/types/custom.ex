defmodule TalkWeb.Type.Custom do
  @moduledoc "Customs GraphQL types and interfaces"

  use Absinthe.Schema.Notation

  @desc "Interface for responses includes success, errors list and data."
  interface :response do
    field :success, non_null(:boolean)
    field :errors, list_of(:error)
    resolve_type fn _, _ -> nil end
  end

  @desc "Error details."
  object :error do
    @desc "The name of the invalid attribute."
    field :attribute, non_null(:string)

    @desc "A human-friendly error message."
    field :message, non_null(:string)
  end

  @desc "A cursor for pagination."
  scalar :cursor do
    parse &Base.url_decode64(&1.value)
    serialize &to_string(&1)
  end

  @desc "ISOz datetime formatISO 8601"
  scalar :time do
    parse &Timex.parse(&1.value, "{ISO:Extended}")
    serialize &Timex.format!(&1, "{ISO:Extended}")
  end

  @desc "Unix timestamp in seconds"
  scalar :timestamp do
    parse(fn %{value: value} -> {:ok, Timex.from_unix(value, :second)} end)
    serialize(fn time -> DateTime.to_unix(Timex.to_datetime(time), :second) end)
  end
end
