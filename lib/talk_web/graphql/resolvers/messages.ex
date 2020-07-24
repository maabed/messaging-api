defmodule TalkWeb.Resolver.Messages do
  @moduledoc "Resolver module for messages queries and mutations"

  import Ecto.Query, warn: false
  import Absinthe.Resolution.Helpers
  require Logger

  alias Ecto.Changeset
  alias Talk.AssetStore
  alias Talk.{Groups, Messages, Medias, Users}
  alias Talk.Schemas.{Group, Message, Report, User}
  alias TalkWeb.Resolver.Helpers
  alias Talk.Messages.Connector
  alias Talk.Reactions.Connector, as: ReactionConnector

  @type info :: %{context: %{user: User.t(), loader: Dataloader.t()} | nil}
  @type mutation_error :: [%{attribute: String.t(), message: String.t()}]
  @type paginated_result :: {:ok, Pagination.Result.t()} | {:error, String.t()}
  @type dataloader_result :: {:middleware, any(), any()}
  @type message_mutation_result :: {:ok, %{success: boolean(), message: Message.t() | nil,
        errors: mutation_error}} | {:error, String.t()}
  @type message_reaction_result :: {:ok, %{success: boolean(), message: Message.t() | nil,
        reaction: MessageReaction.t() | nil, errors: mutation_error}} |{:error, String.t()}
  @type reoprt_mutation_result :: {:ok, %{success: boolean(), report: Report.t() | nil,
        errors: mutation_error}} | {:error, String.t()}

  def messages(%Group{} = group, args, info) do
    Connector.get(group, struct(Connector, args), info)
  end

  @spec messages(map(), info()) :: paginated_result()
  def messages(args, info) do
    Connector.get(nil, struct(Connector, args), info)
  end

  @spec message_sender(Message.t(), map(), info()) :: dataloader_result()
  def message_sender(%Message{profile_id: profile_id} = _message, _args, _info) when is_binary(profile_id) do
    Users.get_user_by_profile_id(profile_id)
  end

  @spec message_media(Message.t(), map(), info()) :: dataloader_result()
  def message_media(%Message{id: id} = _message, _, _info) do
    Medias.get_media_by_message_id(to_string(id))
  end

  @spec media_url(map(), map(), info()) :: paginated_result()
  def media_url(%{filename: filename, extension: extension} = media, _args,  _info) do
    if is_binary(filename) and is_binary(extension) do
      {:ok, AssetStore.media_url(media)}
    else
      {:ok, nil}
    end
  end

  @spec can_edit_message(Message.t(), map(), info()) :: dataloader_result()
  def can_edit_message(%Message{} = message, _, %{context: %{loader: loader, user: user}}) do
    batch_key = User
    item_key = message.profile_id

    loader
    |> Dataloader.load(:db, batch_key, item_key)
    |> on_load(fn loader ->
      loader
      |> Dataloader.get(:db, batch_key, item_key)
      |> check_edit_message_permissions(user)
    end)
  end

  defp check_edit_message_permissions(%User{} = message_sender, user) do
    {:ok, Messages.can_edit?(user, message_sender)}
  end

  defp check_edit_message_permissions(_, _user) do
    {:ok, false}
  end

  @spec reactions(Message.t(), map(), info()) :: paginated_result()
  def reactions(message, args, info) do
    ReactionConnector.get(message, struct(ReactionConnector, args), info)
  end

  @spec create_message(map(), info()) :: message_mutation_result()
  def create_message(args, %{context: %{user: user, __absinthe_plug__: %{uploads: upload}}}) when upload !== %{} do
    with {:ok, group} <- Groups.get_group(user, args.group_id),
         {:ok, true} <- Groups.can_access_group?(user, args.group_id),
         {:ok, %{message: message, media: media}} <-
          Messages.create_message(user, group, Map.merge(Map.put(args, :media, upload["media"]), %{upload: upload})) do
            result =
              case is_map(upload) and not is_nil(media.url) do
                true ->
                  %Message{ message | media: media }

                false ->
                  message
              end
      {:ok, %{success: true, message: result, errors: []}}
    else
      {:error, :message, changeset, _} ->
        {:ok, %{success: false, message: nil, errors: Helpers.format_errors(changeset)}}

      {:ok, false} ->
        {:error, "You are not authorized to perform this action."}

      {:error, :media, :file_type_not_allowed, _} ->
        {:ok, %{
          success: false,
          message: nil,
          errors: [%{attribute: "media", message: "Invalid file type"}]
        }}
      err ->
        err
    end
  end

  @spec create_message(map(), info()) :: message_mutation_result()
  def create_message(args, %{context: %{user: user}} = _context) do
    with {:ok, group} <- Groups.get_group(user, args.group_id),
         {:ok, true} <- Groups.can_access_group?(user, args.group_id),
         {:ok, %{message: message}} <- Messages.create_message(user, group, args) do
      {:ok, %{success: true, message: message, errors: []}}
    else
      {:error, :message, changeset, _} ->
        {:ok, %{success: false, message: nil, errors: Helpers.format_errors(changeset)}}

      {:ok, false} ->
        {:error, "You are not authorized to perform this action."}

      err ->
        err
    end
  end

  @spec list_recipients(Message.t(), map(), info()) :: message_mutation_result()
  def list_recipients(%Message{id: id, profile_id: _profile_id} = _message, _args, %{context: %{user: user}}) do
    with {:ok, group} <- Groups.get_group_by_message_id(user.profile_id, id),
         {:ok, users} <- Groups.list_recipients(group, id) do
      {:ok, users}
    else
      {:error, changeset} ->
        {:ok, %{success: false, message: nil, errors: Helpers.format_errors(changeset)}}

      err ->
        err
    end
  end

  @spec update_message(map(), info()) :: message_mutation_result()
  def update_message(args, %{context: %{user: user}}) do
    with {:ok, message} <- Messages.get_message(user, args.message_id),
         {:ok, %{updated_message: updated_message}} <- Messages.update_message(user, message, args) do
      {:ok, %{success: true, message: updated_message, errors: []}}
    else
      {:error, :updated_message, changeset, _} ->
        {:ok, %{success: false, message: nil, errors: Helpers.format_errors(changeset)}}
      err ->
        err
    end
  end

  @spec mark_as_request(map(), info()) :: message_mutation_result()
  def mark_as_request(args, %{context: %{user: user}}) do
    with {:ok, true} <- Groups.can_access_group?(user, args.group_id),
         {:ok, messages} <- Messages.get_messages(user, args.message_ids),
         {:ok, updated_messages} <- Messages.mark_as_request(user, messages) do
      {:ok, %{success: true, messages: updated_messages, errors: []}}
    else
      {:ok, false} ->
        {:error, "You are not authorized to perform this action."}

      {:error, :updated_message, changeset, _} ->
        {:ok, %{success: false, message: nil, errors: Helpers.format_errors(changeset)}}

      err ->
        err
    end
  end

  @spec mark_as_not_request(map(), info()) :: message_mutation_result()
  def mark_as_not_request(args, %{context: %{user: user}}) do
    with {:ok, true} <- Groups.can_access_group?(user, args.group_id),
         {:ok, messages} <- Messages.get_messages(user, args.message_ids),
         {:ok, updated_messages} <- Messages.mark_as_not_request(user, messages) do
      {:ok, %{success: true, messages: updated_messages, errors: []}}
    else
      {:ok, false} ->
        {:error, "You are not authorized to perform this action."}

      {:error, :updated_message, changeset, _} ->
        {:ok, %{success: false, message: nil, errors: Helpers.format_errors(changeset)}}

      err ->
        err
    end
  end

  @spec delete_message(map(), info()) :: message_mutation_result()
  def delete_message(args, %{context: %{user: user}}) do
    with {:ok, message} <- Messages.get_message(user, args.message_id),
         true <- Messages.can_edit?(user, message),
         {:ok, deleted_message} <- Messages.delete_message(user, message) do
      {:ok, %{success: true, message: deleted_message, errors: []}}
    else
      {:error, changeset} ->
        {:ok, %{success: false, message: nil, errors: Helpers.format_errors(changeset)}}

      false ->
        {:error, "You are not authorized to perform this action."}

      err ->
        err
    end
  end

  @spec mark_as_unread(map(), info()) :: message_mutation_result()
  def mark_as_unread(args, %{context: %{user: user}}) do
    with {:ok, group} <- Groups.get_group(user, args.group_id),
         {:ok, true} <- Groups.can_access_group?(user, args.group_id),
         {:ok, messages} <- Messages.get_messages(user, args.message_ids),
         {:ok, unread_messages} <- Messages.mark_as_unread(user.profile, group, messages) do
      {:ok, %{success: true, messages: unread_messages, errors: []}}
    else
      {:error, changeset} ->
        {:ok, %{success: false, message: nil, errors: Helpers.format_errors(changeset)}}

      {:ok, false} ->
        {:error, "You are not authorized to perform this action."}

      err ->
        err
    end
  end

  @spec mark_as_read(map(), info()) :: message_mutation_result()
  def mark_as_read(args, %{context: %{user: user}}) do
    with {:ok, group} <- Groups.get_group(user, args.group_id),
         {:ok, true} <- Groups.can_access_group?(user, args.group_id),
         {:ok, messages} <- Messages.get_messages(user, args.message_ids),
         {:ok, read_messages} <- Messages.mark_as_read(user.profile, group, messages) do
      {:ok, %{success: true, messages: read_messages, errors: []}}
    else
      {:error, changeset} ->
        {:ok, %{success: false, message: nil, errors: Helpers.format_errors(changeset)}}

      {:ok, false} ->
        {:error, "You are not authorized to perform this action."}

      err ->
        err
    end
  end

  @spec mark_all_as_read(map(), info()) :: message_mutation_result()
  def mark_all_as_read(%{group_id: group_id}, %{context: %{user: user}}) do
    with {:ok, group} <- Groups.get_group(user, group_id),
         {:ok, true} <- Groups.can_access_group?(user, group_id),
         {:ok, read_count} <- Messages.mark_all_as_read(user.profile, group) do
      {:ok, %{success: true, read: read_count, errors: []}}
    else
      {:error, changeset} ->
        {:ok, %{success: false, read: nil, errors: Helpers.format_errors(changeset)}}

      {:ok, false} ->
        {:error, "You are not authorized to perform this action."}

      err ->
        err
    end
  end

  @spec mark_all_as_read(map(), info()) :: message_mutation_result()
  def mark_all_as_read(%{profile_id: profile_id}, %{context: %{user: current_user}}) do
    with {:ok, user} <- Users.get_user_by_profile_id(current_user, profile_id),
         {:ok, read_count} <- Messages.mark_all_as_read(user.profile) do
      {:ok, %{success: true, read: read_count, errors: []}}
    else
      {:error, changeset} ->
        {:ok, %{success: false, read: nil, errors: Helpers.format_errors(changeset)}}

      {:ok, false} ->
        {:error, "You are not authorized to perform this action."}

      err ->
        err
    end
  end

  @spec create_message_reaction(map(), info()) :: message_reaction_result()
  def create_message_reaction(args, %{context: %{user: user}}) do
    with {:ok, message} <- Messages.get_message(user, args.message_id),
         {:ok, reaction} <- Messages.create_message_reaction(user, message, args.value) do
      {:ok, %{success: true, errors: [], message: message, reaction: reaction}}
    else
      {:error, %Changeset{} = changeset} ->
        {:ok, %{success: false, errors: Helpers.format_errors(changeset), message: nil}}

      err ->
        err
    end
  end

  @spec delete_message_reaction(map(), info()) :: message_reaction_result()
  def delete_message_reaction(args, %{context: %{user: user}}) do
    with {:ok, message} <- Messages.get_message(user, args.message_id),
         {:ok, reaction} <- Messages.delete_message_reaction(user, message, args.value) do
      {:ok, %{success: true, errors: [], message: message, reaction: reaction}}
    else
      {:error, %Changeset{} = changeset} ->
        {:ok, %{success: false, errors: Helpers.format_errors(changeset), message: nil, reaction: nil}}

      err ->
        err
    end
  end

  @spec read_status(Message.t(), map(), info()) :: :message_read_status | nil
  def read_status(%Message{id: id, profile_id: profile_id} = _message, _args, _info) do
    with {:ok, group} <- Groups.get_group_by_message_id(profile_id, id),
         {:ok, read_status} <- Messages.get_message_read_status(group, id, profile_id) do
      {:ok, read_status}
    else
      {:error, changeset} ->
        {:ok, %{success: false, message: nil, errors: Helpers.format_errors(changeset)}}
      err ->
        err
    end
  end

  @spec create_report(map(), info()) :: message_reaction_result()
  def create_report(args, %{context: %{user: user}}) do
    with {:ok, _reported_profile} <- Users.get_user_by_profile_id(args.author_id),
         {:ok, report} <- Messages.create_report(user, args) do
      {:ok, %{success: true, errors: [], report: report}}
    else
      {:error, %Changeset{} = changeset} ->
        {:ok, %{success: false, errors: Helpers.format_errors(changeset), message: nil}}

      err ->
        err
    end
  end
end
