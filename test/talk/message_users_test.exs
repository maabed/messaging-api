defmodule Talk.MessageUsersTest do
  use Talk.DataCase

  alias Talk.MessageUsers

  describe "message_users" do
    alias Talk.Schemas.MessageUser

    @valid_attrs %{bookmaked: true, read_at: "2010-04-17T14:00:00Z", status: "some status"}
    @update_attrs %{bookmaked: false, read_at: "2011-05-18T15:01:01Z", status: "some updated status"}
    @invalid_attrs %{bookmaked: nil, read_at: nil, status: nil}

    def message_user_fixture(attrs \\ %{}) do
      {:ok, message_user} =
        attrs
        |> Enum.into(@valid_attrs)
        |> MessageUsers.create_message_user()

      message_user
    end

    test "list_message_users/0 returns all message_users" do
      message_user = message_user_fixture()
      assert MessageUsers.list_message_users() == [message_user]
    end

    test "get_message_user!/1 returns the message_user with given id" do
      message_user = message_user_fixture()
      assert MessageUsers.get_message_user!(message_user.id) == message_user
    end

    test "create_message_user/1 with valid data creates a message_user" do
      assert {:ok, %MessageUser{} = message_user} = MessageUsers.create_message_user(@valid_attrs)
      assert message_user.bookmaked == true
      assert message_user.read_at == DateTime.from_naive!(~N[2010-04-17T14:00:00Z], "Etc/UTC")
      assert message_user.status == "some status"
    end

    test "create_message_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = MessageUsers.create_message_user(@invalid_attrs)
    end

    test "update_message_user/2 with valid data updates the message_user" do
      message_user = message_user_fixture()
      assert {:ok, %MessageUser{} = message_user} = MessageUsers.update_message_user(message_user, @update_attrs)
      assert message_user.bookmaked == false
      assert message_user.read_at == DateTime.from_naive!(~N[2011-05-18T15:01:01Z], "Etc/UTC")
      assert message_user.status == "some updated status"
    end

    test "update_message_user/2 with invalid data returns error changeset" do
      message_user = message_user_fixture()
      assert {:error, %Ecto.Changeset{}} = MessageUsers.update_message_user(message_user, @invalid_attrs)
      assert message_user == MessageUsers.get_message_user!(message_user.id)
    end

    test "delete_message_user/1 deletes the message_user" do
      message_user = message_user_fixture()
      assert {:ok, %MessageUser{}} = MessageUsers.delete_message_user(message_user)
      assert_raise Ecto.NoResultsError, fn -> MessageUsers.get_message_user!(message_user.id) end
    end

    test "change_message_user/1 returns a message_user changeset" do
      message_user = message_user_fixture()
      assert %Ecto.Changeset{} = MessageUsers.change_message_user(message_user)
    end
  end
end
