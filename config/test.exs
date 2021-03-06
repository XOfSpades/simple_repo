use Mix.Config

config :simple_repo, ecto_repos: [SimpleRepo.Support.Repo]

config :simple_repo, SimpleRepo.Support.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "simple_repo_test",
  username: "simple_repo",
  password: "exs#exs456",
  hostname: "simple-repo-postgres-test-s",
  port: "5432",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# Do not include metadata nor timestamps in development logs
config :logger, :console, level: :warn, format: "[$level] $message\n"

