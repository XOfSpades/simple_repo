use Mix.Config

config :simple_repo, ecto_repos: [SimpleRepo.Support.Repo]

config :simple_repo, SimpleRepo.Support.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "simple_repo_dev",
  username: "simple_repo",
  password: "exs#exs456",
  hostname: "simple-repo-postgres-dev-s",
  port: "5432",
  pool_size: 10


config :simple_repo, :repo,
  module_name: SimpleRepo.Support.Repo

# Do not include metadata nor timestamps in development logs
config :logger, :console, level: :info, format: "[$level] $message\n"
