defmodule SimpleRepo.Support.Fixtures do
  @moduledoc """
  Only used for testing purpose.
  """

  alias SimpleRepo.Support.TestStruct
  alias SimpleRepo.Support.Repo

  def test_structs do
    [
      %TestStruct{name: "S1", type: "foo", value: 1, f_value: nil},
      %TestStruct{name: "S2", type: "foo", value: 2, f_value: 42.2},
      %TestStruct{name: "S3", type: "foo", value: 2, f_value: 41.3},
      %TestStruct{name: "S4", type: "bar", value: 4, f_value: 42.2},
      %TestStruct{name: "S5", type: "bar", value: 5, f_value: 39.7},
      %TestStruct{name: "S6", type: "baz", value: 6, f_value: 43.1},
      %TestStruct{name: "S7", type: "baz", value: nil, f_value: nil}
    ] |> Enum.map(&Repo.insert!/1)
    Repo.all(TestStruct)
  end
end
