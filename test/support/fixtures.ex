defmodule SimpleRepo.Support.Fixtures do
  alias SimpleRepo.Support.TestStruct
  alias SimpleRepo.Support.Repo

  def test_structs do
    [
      %TestStruct{name: "S1", type: "foo", value: 1},
      %TestStruct{name: "S2", type: "foo", value: 2},
      %TestStruct{name: "S3", type: "foo", value: 2},
      %TestStruct{name: "S4", type: "bar", value: 4},
      %TestStruct{name: "S5", type: "bar", value: 5},
      %TestStruct{name: "S6", type: "baz", value: 6},
      %TestStruct{name: "S7", type: "baz", value: nil}
    ] |> Enum.map(&(Repo.insert!(&1)))
    Repo.all(TestStruct)
  end
end
