defmodule Talk.GroupUsersTest do
  use Talk.DataCase

  alias Talk.GroupUsers

  describe "group_users" do
    alias Talk.Schemas.GroupUser

    @valid_attrs %{msg_count: 42, role: "some role", status: "some status", unread_count: 42}
    @update_attrs %{msg_count: 43, role: "some updated role", status: "some updated status", unread_count: 43}
    @invalid_attrs %{msg_count: nil, role: nil, status: nil, unread_count: nil}

    def group_user_fixture(attrs \\ %{}) do
      {:ok, group_user} =
        attrs
        |> Enum.into(@valid_attrs)
        |> GroupUsers.create_group_user()

      group_user
    end

    test "list_group_users/0 returns all group_users" do
      group_user = group_user_fixture()
      assert GroupUsers.list_group_users() == [group_user]
    end

    test "get_group_user!/1 returns the group_user with given id" do
      group_user = group_user_fixture()
      assert GroupUsers.get_group_user!(group_user.id) == group_user
    end

    test "create_group_user/1 with valid data creates a group_user" do
      assert {:ok, %GroupUser{} = group_user} = GroupUsers.create_group_user(@valid_attrs)
      assert group_user.msg_count == 42
      assert group_user.role == "some role"
      assert group_user.status == "some status"
      assert group_user.unread_count == 42
    end

    test "create_group_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = GroupUsers.create_group_user(@invalid_attrs)
    end

    test "update_group_user/2 with valid data updates the group_user" do
      group_user = group_user_fixture()
      assert {:ok, %GroupUser{} = group_user} = GroupUsers.update_group_user(group_user, @update_attrs)
      assert group_user.msg_count == 43
      assert group_user.role == "some updated role"
      assert group_user.status == "some updated status"
      assert group_user.unread_count == 43
    end

    test "update_group_user/2 with invalid data returns error changeset" do
      group_user = group_user_fixture()
      assert {:error, %Ecto.Changeset{}} = GroupUsers.update_group_user(group_user, @invalid_attrs)
      assert group_user == GroupUsers.get_group_user!(group_user.id)
    end

    test "delete_group_user/1 deletes the group_user" do
      group_user = group_user_fixture()
      assert {:ok, %GroupUser{}} = GroupUsers.delete_group_user(group_user)
      assert_raise Ecto.NoResultsError, fn -> GroupUsers.get_group_user!(group_user.id) end
    end

    test "change_group_user/1 returns a group_user changeset" do
      group_user = group_user_fixture()
      assert %Ecto.Changeset{} = GroupUsers.change_group_user(group_user)
    end
  end
end
