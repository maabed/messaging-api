# defmodule Talk.SapienDB.ApiHooks do
#   @moduledoc "filter sapien users changes"

#   require Logger

#   alias Talk.Repo
#   alias Talk.Users
#   alias Ecto.Changeset
#   alias Talk.Schemas.{BlockedProfile, Follower}

#   def perform(%{"trigger" => trigger} = payload) when trigger === "insert_user" do
#     # inserted = parse_timestamp(payload["inserted_at"])
#     # updated = parse_timestamp(payload["updated_at"])

#     params =
#       payload
#       |> Map.delete("trigger")
#       # |> Map.merge(%{"inserted_at" => inserted})
#       # |> Map.merge(%{"updated_at" => updated})

#     with {:ok, _user} <- Users.create_user(params) do
#       {:ok, true}
#     else
#       {:error, %Changeset{} = changeset} ->
#         {:error, :unexpected_payload , changeset}
#       err ->
#         err
#     end
#   end

#   def perform(%{"trigger" => trigger} = payload) when trigger === "update_user" do
#     params =
#       payload
#       |> Map.delete("trigger")

#     with {:ok, user} <- Users.get_user_by_id(params["id"]),
#          {:ok, _} <- Users.update_user(user, params) do
#       {:ok, true}
#     else
#       {:error, %Changeset{} = changeset} ->
#         {:error, :unexpected_payload , changeset}
#       err ->
#         err
#     end
#   end

#   def perform(%{"trigger" => trigger} = payload) when trigger === "delete_user" do
#     with {:ok, user} <- Users.get_user_by_id(payload["id"]),
#          {:ok, true} <- Users.delete_user(user) do
#       {:ok, true}
#     else
#       {:error, %Changeset{} = changeset} ->
#         {:error, :unexpected_payload , changeset}
#       err ->
#         err
#     end
#   end

#   def perform(%{"trigger" => trigger} = payload) when trigger === "insert_follower" do
#     Logger.info "perform insert_follower => payload #{inspect payload}."

#     %Follower{}
#     |> Follower.create_changeset(%{
#       follower_id: payload["follower_id"],
#       following_id: payload["following_id"]
#     })
#     |> Repo.insert(on_conflict: :nothing)

#     {:ok, true}
#   end

#   def perform(%{"trigger" => trigger} = payload) when trigger === "delete_follower" do
#     Logger.info "perform delete_follower => payload #{inspect payload}."
#     case Repo.get_by(Follower,
#       follower_id: payload["follower_id"],
#       following_id: payload["following_id"])
#       do
#         nil -> {:error, :not_found}
#         %Follower{} = follower ->
#           Repo.delete(follower)
#           {:ok, true}
#     end
#   end

#   def perform(%{"trigger" => trigger} = payload) when trigger === "insert_block" do
#     Logger.info "perform insert_block => payload #{inspect payload}."

#     %BlockedProfile{}
#     |> BlockedProfile.create_changeset(%{
#       blocked_by_id: payload["blocked_by_id"],
#       blocked_profile_id: payload["blocked_profile_id"]
#     })
#     |> Repo.insert(on_conflict: :nothing)

#     {:ok, true}
#   end

#   def perform(%{"trigger" => trigger} = payload) when trigger === "delete_block" do
#     Logger.info "perform delete_block => payload #{inspect payload}."

#     case Repo.get_by(
#       BlockedProfile,
#         blocked_by_id: payload["blocked_by_id"],
#         blocked_profile_id: payload["blocked_profile_id"]
#       ) do
#           nil -> {:error, :not_found}
#           blocked ->
#             Repo.delete(blocked)
#             {:ok, true}
#     end
#   end

#   def perform(_), do: {:error, :unexpected_payload}

#   def parse_timestamp(time) do
#     formatted =
#       time
#       |> String.slice(0..-4)
#       |> Timex.parse!("%Y-%m-%d %H:%M:%S.%L", :strftime)

#     with usec <-  DateTime.from_naive!(formatted, "Etc/UTC") do
#       %DateTime{usec | microsecond: {Enum.random(100_000..999_999), 6}}
#     end
#   end
# end
