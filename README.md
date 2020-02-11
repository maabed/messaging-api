# Sapien chat (Talk)

## Development setup

You'll need to install the following dependencies first:

* [Elixir](https://elixir-lang.org/install.html) 1.10.0
* [PostgreSQL](https://postgresapp.com/) 11

To start chat server:

* Create `.env` file and copy is content from 1password [file](https://sapien.1password.com/vaults/ajcgx3zogtvg6xo7qkzou5jjd4/allitems/whypdk7xhjabpmijt76osgesl4)
* Install dependencies with `mix deps.get`
* Create and migrate database with `mix ecto.setup`
* Start Phoenix endpoint with `source .env && iex -S mix phx.server`

Graphql endpoint at [`localhost:7000/chat-graphql`](http://localhost:7000/graphql)
GraphiQL playground at [`localhost:7000/graphiql`](http://localhost:7000/graphiql)

## Docker setup
* copy .env contents to new .env_dovker file and remove `export` from ech environment variable
* create `pgdata` and `build` directory to store docker volumes 
* build image `--tag local-talk:latest -t sapien-talk . `
* start `docker-compose --env-file .env_docker up`
* stop `docker-compose --env-file .env_docker down`
* rebuild using compose `docker-compose --env-file .env_docker up --build --force-recreate --renew-anon-volumes`
* ssh into app container `docker exec -it local-talk bash`
* ssh into db container `docker exec -it local-db bash`

## Generat JWT tokon
If you want to generate JWT token for a user use `mix talk.get_auth_token --username <username>`. Its  also accepts `--id <id>` and `--email <email>` params.
