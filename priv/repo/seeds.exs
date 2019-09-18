# Script for populating the database. You can run it as:
#     mix run priv/repo/seeds.exs

alias Talk.SapienDB.Sync

Sync.sync_users()
:timer.sleep(:timer.seconds(5))

Sync.sync_followers()
:timer.sleep(:timer.seconds(5))

Sync.sync_blocked_profiles()
:timer.sleep(:timer.seconds(5))

