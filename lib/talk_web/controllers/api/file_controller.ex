defmodule TalkWeb.API.FileController do
  @moduledoc false

  use TalkWeb, :controller
  require Logger
  alias Talk.{Groups, Messages}
  alias Talk.Schemas.Message

  def create(conn, params) do
    params
    |> case do
      %{"media" => _media, "group_id" => group_id, "content" => _content, "recipient_ids" => _recipient_ids, "is_request" => _is_request} ->

        args =
          params
          |> Enum.reduce(%{}, fn ({key, val}, acc) -> Map.put(acc, String.to_atom(key), val) end)

        with {:ok, group} <- Groups.get_group(conn.assigns.user, group_id),
              {:ok, true} <- Groups.can_access_group?(conn.assigns.user, group_id),
              {:ok, %{message: message, media: media}} <-
              Messages.create_message(conn.assigns.user, group, args) do
                result =
                  case is_map(media) and not is_nil(media.url) do
                    true ->
                      %Message{ message | media: media }
                    false ->
                      message
                  end

            json(conn, %{
              success: true,
              message: %{
                id: result.id,
                content: result.content,
                is_request: result.is_request,
                profile_id: result.profile_id,
                group_id: group_id,
                type: result.type,
                inserted_at: result.inserted_at,
                media: %{
                  id: result.media.id,
                  url: result.media.url,
                  extension: result.media.extension,
                  filename: result.media.filename,
                  size: result.media.size
                }
              },
              errors: []
            })

        else
          :error ->
            json(conn, %{
              success: false,
              message: nil,
              errors: [%{attribute: "files API", message: "unknown error"}]
            })

          _ ->
            json(conn, %{
              success: false,
              message: nil,
              errors: [%{attribute: "files API", message: "unprocessable entity"}]
            })
        end

      _ ->
        json(conn, %{
          success: false,
          message: nil,
          errors: [%{attribute: "files API", message: "unprocessable entity"}]
        })
    end
  end
end
