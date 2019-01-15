defmodule SimpleRepo.Support.Fixtures do
  @moduledoc """
  Only used for testing purpose.
  """

  alias SimpleRepo.Support.TestStruct
  alias SimpleRepo.Support.Repo

  def test_structs do
    time1 = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:millisecond)
    time2 = NaiveDateTime.add(time1, 2, :second) |> NaiveDateTime.truncate(:millisecond)
    time3 = NaiveDateTime.add(time2, 2, :second) |> NaiveDateTime.truncate(:millisecond)
    [
      %{name: "S1", type: "foo", value: 1, f_value: nil},
      %{name: "S2", type: "foo", value: 2, f_value: 42.2},
      %{name: "S3", type: "foo", value: 2, f_value: 41.3},
      %{name: "S4", type: "bar", value: 4, f_value: 42.2},
      %{name: "S5", type: "bar", value: 5, f_value: 39.7},
      %{name: "S6", type: "baz", value: 6, f_value: 43.1},
      %{name: "S7", type: "baz", value: nil, f_value: nil}
    ]
    |> Enum.zip(Stream.cycle([time1, time2, time3, nil]))
    |> Enum.map(fn {struct, time} -> Map.put(struct, :some_time, time) end)
    |> Enum.map(fn params -> TestStruct.changeset(%TestStruct{}, params) end)
    |> Enum.map(&Repo.insert!/1)

    Repo.all(TestStruct)
  end
end
