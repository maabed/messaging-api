defmodule TalkWeb.Type.Enum do
  @moduledoc "Enums for groups, messages and users"

  use Absinthe.Schema.Notation

  enum :group_status do
    value :open, as: "OPEN"
    value :closed, as: "CLOSED"
    value :deleted, as: "DELETED"
  end

  enum :group_user_status do
    value :muted, as: "MUTED"
    value :archived, as: "ARCHIVED"
    value :subscribed, as: "SUBSCRIBED"
    value :unsubscribed, as: "UNSUBSCRIBED"
  end

  enum :group_user_role do
    value :admin, as: "ADMIN"
    value :owner, as: "OWNER"
    value :member, as: "MEMBER"
  end

  enum :message_status do
    value :valid, as: "VALID"
    value :expired, as: "EXPIRED"
    value :deleted, as: "DELETED"
  end

  enum :message_read_status do
    value :read, as: "READ"
    value :unread, as: "UNREAD"
  end

  enum :read_status_filter do
    value :read
    value :unread
    value :all
  end

  enum :message_status_filter do
    value :valid
    value :expired
    value :deleted
    value :all
  end

  enum :group_status_filter do
    value :open
    value :closed
    value :deleted
    value :all
  end

  enum :last_activity_filter do
    value :today
    value :all
  end

  enum :subscribe_status_filter do
    value :subscribed
    value :unsubscribed
    value :all
  end

  enum :type_filter do
    value :direct
    value :group
    value :all
  end

  enum :request_status_filter do
    value :follower
    value :request
    value :all
  end

  enum :user_order_field do
    value :username
    value :inserted_at
    value :rank
  end

  enum :group_order_field do
    value :name
    value :inserted_at
  end

  enum :message_order_field do
    value :last_activity_at
    value :inserted_at
    value :type
  end

  enum :reaction_order_field do
    value :inserted_at
  end

  enum :order_direction do
    value :asc
    value :desc
  end
end
