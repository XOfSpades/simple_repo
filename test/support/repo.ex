defmodule SimpleRepo.Support.Repo do
  @moduledoc """
  Only used for testing purpose.
  """
  use Ecto.Repo, otp_app: :simple_repo, adapter: Ecto.Adapters.Postgres
  use SimpleRepo.Scoped, repo: __MODULE__
end
