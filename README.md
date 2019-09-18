# Sapien chat (Talk)

## Development setup

You'll need to install the following dependencies first:

* [Elixir](https://elixir-lang.org/install.html) 1.9.0
* [PostgreSQL](https://postgresapp.com/) 11

To start chat server:

* Create `.env` file and copy is content from 1password [file](https://sapien.1password.com/vaults/ajcgx3zogtvg6xo7qkzou5jjd4/allitems/whypdk7xhjabpmijt76osgesl4)
* Copy jwt RSA key pairs from same 1password file under **Related Items** section, to `priv/keys/`
* Install dependencies with `mix deps.get`
* Create and migrate database with `mix ecto.setup`
* Make sure sapien app is up using [DEV-2632-sync-db](https://github.com/SapienNetwork/sapien-v2-backend/tree/DEV-2632-sync-db) branch.
* Create a user on Sapien App or use [mix task below](#creating-user-and-generat-JWT-tokon).
* Seed sapien users/followers tables into chat db with `mix run priv/repo/seeds.exs`
* Start Phoenix endpoint with `source .env && iex -S mix phx.server`

Graphql endpoint at [`localhost:7000/graphql`](http://localhost:7000/graphql)
GraphiQL playground at [`localhost:7000/graphiql`](http://localhost:7000/graphiql)

### Creating user and generat JWT tokon

Run `mix talk.create_user`
This will return a JWT token for the created user, then you can set in GraphiQL playground, Postman or Insomnia clients as the `authorization` HTTP header. Like this: `authorization: Bearer <token>`.

If you want to use one of the sapien users can use `mix talk.get_auth_token --username <username>`. Its also used if the token expires.
The command also accepts `--id <id>` and `--email <email>` params.
