defmodule SimpleRepo.Support.RepoCase do
  @moduledoc """
  This module defines the test case to be used by
  model tests.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Alias the data repository and import query/model functions
      alias SimpleRepo.Support.Repo
      import Ecto.Query, only: [from: 2]
    end
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(SimpleRepo.Support.Repo)
  end
end
