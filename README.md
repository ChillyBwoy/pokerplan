# Pokerplan

https://pokerplan.fly.dev

## Requirements

Create a `Client ID` and a `Client Secret` for GitHub https://github.com/settings/developers

Create a secret token. You can use any string or generate one using the following command:

```sh
mix phx.gen.secret
```

Create a `.env` file and add your token and GitHub credentials to it.

```bash
export AUTH_TOKEN_SECRET=...
export GITHUB_CLIENT_ID=...
export GITHUB_CLIENT_SECRET=...
```

Run `source .env` to load the environment variables.

Run `mix deps.get` to install the dependencies.

Run `mix phx.server` to start the server.
