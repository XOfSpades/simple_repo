defmodule SimpleRepo.Support.TestRepository do
  @moduledoc """
  Only used for testing purpose.
  """
  use SimpleRepo.Repository, repo: SimpleRepo.Support.Repo
end
