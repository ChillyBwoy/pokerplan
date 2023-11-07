import Config

config :ueberauth, Ueberauth,
  providers: [
    github: {
      Ueberauth.Strategy.Github,
      [
        default_scope: "user",
        request_path: "/auth/signin/github",
        callback_path: "/auth/signin/github/callback",
        allow_private_emails: true
      ]
    }
  ]

config :ueberauth, Ueberauth.Strategy.Github.OAuth,
  client_id: System.get_env("GITHUB_CLIENT_ID"),
  client_secret: System.get_env("GITHUB_CLIENT_SECRET")
