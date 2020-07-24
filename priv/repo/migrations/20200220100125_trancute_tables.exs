defmodule Talk.Repo.Migrations.TrancuteTables do
  use Ecto.Migration

  def change do
    execute """
      TRUNCATE
        groups,
        group_users,
        messages,
        message_logs,
        message_reactions,
        message_groups,
        media_object,
        chat_reports
      RESTART IDENTITY CASCADE;
      """
  end
end
