defmodule Talk.GroupsTest do
  use Talk.DataCase

  alias Talk.Groups

  describe "groups" do
    alias Talk.Groups.Group

    @valid_attrs %{description: "some description", is_private: true, last_message_id: "some last_message_id", picture: "some picture", status: "some status", title: "some title"}
    @update_attrs %{description: "some updated description", is_private: false, last_message_id: "some updated last_message_id", picture: "some updated picture", status: "some updated status", title: "some updated title"}
    @invalid_attrs %{description: nil, is_private: nil, last_message_id: nil, picture: nil, status: nil, title: nil}

    def group_fixture(attrs \\ %{}) do
      {:ok, group} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Groups.create_group()

      group
    end

    test "list_groups/0 returns all groups" do
      group = group_fixture()
      assert Groups.list_groups() == [group]
    end

    test "get_group!/1 returns the group with given id" do
      group = group_fixture()
      assert Groups.get_group!(group.id) == group
    end

    test "create_group/1 with valid data creates a group" do
      assert {:ok, %Group{} = group} = Groups.create_group(@valid_attrs)
      assert group.description == "some description"
      assert group.is_private == true
      assert group.last_message_id == "some last_message_id"
      assert group.picture == "some picture"
      assert group.status == "some status"
      assert group.title == "some title"
    end

    test "create_group/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Groups.create_group(@invalid_attrs)
    end

    test "update_group/2 with valid data updates the group" do
      group = group_fixture()
      assert {:ok, %Group{} = group} = Groups.update_group(group, @update_attrs)
      assert group.description == "some updated description"
      assert group.is_private == false
      assert group.last_message_id == "some updated last_message_id"
      assert group.picture == "some updated picture"
      assert group.status == "some updated status"
      assert group.title == "some updated title"
    end

    test "update_group/2 with invalid data returns error changeset" do
      group = group_fixture()
      assert {:error, %Ecto.Changeset{}} = Groups.update_group(group, @invalid_attrs)
      assert group == Groups.get_group!(group.id)
    end

    test "delete_group/1 deletes the group" do
      group = group_fixture()
      assert {:ok, %Group{}} = Groups.delete_group(group)
      assert_raise Ecto.NoResultsError, fn -> Groups.get_group!(group.id) end
    end

    test "change_group/1 returns a group changeset" do
      group = group_fixture()
      assert %Ecto.Changeset{} = Groups.change_group(group)
    end
  end
end
