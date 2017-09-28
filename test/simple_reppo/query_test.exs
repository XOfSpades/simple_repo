defmodule SimpleRepo.QueryTest do
  use ExUnit.Case, async: true
  use SimpleRepo.Support.RepoCase
  alias SimpleRepo.Support.Repo
  alias SimpleRepo.Support.TestStruct
  alias SimpleRepo.Query

  setup do
    structs = SimpleRepo.Support.Fixtures.test_structs
    {:ok, structs: structs}
  end

  describe ".scoped" do
    test "scoped to a single value", %{structs: structs} do
      results = Query.scoped(TestStruct, [type: "foo"]) |> Repo.all
      assert length(results) == 3

      struct_data = structs
      |> Enum.filter(fn(x) -> x.type == "foo" end)
      |> Enum.map(fn(x) -> Map.take(x, [:name, :type, :value]) end)

      result_data = results
      |> Enum.map(fn(x) -> Map.take(x, [:name, :type, :value]) end)

      for expected <- struct_data do
        assert Enum.member?(result_data, expected)
      end
    end

    test "allows any kind of tuple enum", %{structs: structs} do
      results = Query.scoped(TestStruct, [{"type", "foo"}]) |> Repo.all
      assert length(results) == 3

      struct_data = structs
      |> Enum.filter(fn(x) -> x.type == "foo" end)
      |> Enum.map(fn(x) -> Map.take(x, [:name, :type, :value]) end)

      result_data = results
      |> Enum.map(fn(x) -> Map.take(x, [:name, :type, :value]) end)

      for expected <- struct_data do
        assert Enum.member?(result_data, expected)
      end
    end

    test "scoped to a single nil value", %{structs: structs} do
      results = Query.scoped(TestStruct, [value: nil]) |> Repo.all
      assert length(results) == 1

      struct_data = structs
      |> Enum.filter(fn(x) -> is_nil(x.value) end)
      |> Enum.map(fn(x) -> Map.take(x, [:name, :type, :value]) end)

      result_data = results
      |> Enum.map(fn(x) -> Map.take(x, [:name, :type, :value]) end)

      for expected <- struct_data do
        assert Enum.member?(result_data, expected)
      end
    end

    test "scoped to a single atom value", %{structs: structs} do
      results = Query.scoped(TestStruct, [type: :foo]) |> Repo.all
      assert length(results) == 3

      struct_data = structs
      |> Enum.filter(fn(x) -> x.type == "foo" end)
      |> Enum.map(fn(x) -> Map.take(x, [:name, :type, :value]) end)

      result_data = results
      |> Enum.map(fn(x) -> Map.take(x, [:name, :type, :value]) end)

      for expected <- struct_data do
        assert Enum.member?(result_data, expected)
      end
    end

    test "scopes to items not equal to value", %{structs: structs} do
      results = Query.scoped(TestStruct, [type: {:not, "foo"}]) |> Repo.all
      assert length(results) == 4

      struct_data = structs
      |> Enum.filter(fn(x) -> x.type != "foo" end)
      |> Enum.map(fn(x) -> Map.take(x, [:name, :type, :value]) end)

      result_data = results
      |> Enum.map(fn(x) -> Map.take(x, [:name, :type, :value]) end)

      for expected <- struct_data do
        assert Enum.member?(result_data, expected)
      end
    end

    test "scopes to items with non-nil field", %{structs: structs} do
      results = Query.scoped(TestStruct, [value: {:not, nil}]) |> Repo.all
      assert length(results) == 6

      struct_data = structs
      |> Enum.filter(fn(x) -> x.value end)
      |> Enum.map(fn(x) -> Map.take(x, [:name, :type, :value]) end)

      result_data = results
      |> Enum.map(fn(x) -> Map.take(x, [:name, :type, :value]) end)

      for expected <- struct_data do
        assert Enum.member?(result_data, expected)
      end
    end

    test "scopes to items included in a list", %{structs: structs} do
      results = TestStruct
      |> Query.scoped([type: ["foo", "bar"]])
      |> Repo.all

      assert length(results) == 5

      struct_data = structs
      |> Enum.filter(fn(x) -> x.type == "foo" || x.type == "bar" end)
      |> Enum.map(fn(x) -> Map.take(x, [:name, :type, :value]) end)

      result_data = results
      |> Enum.map(fn(x) -> Map.take(x, [:name, :type, :value]) end)

      for expected <- struct_data do
        assert Enum.member?(result_data, expected)
      end
    end

    test "scopes to items not included in a list", %{structs: structs} do
      results = TestStruct
      |> Query.scoped([type: {:not, ["foo", "bar"]}])
      |> Repo.all

      assert length(results) == 2

      struct_data = structs
      |> Enum.filter(fn(x) -> x.type == "baz" end)
      |> Enum.map(fn(x) -> Map.take(x, [:name, :type, :value]) end)

      result_data = results
      |> Enum.map(fn(x) -> Map.take(x, [:name, :type, :value]) end)

      for expected <- struct_data do
        assert Enum.member?(result_data, expected)
      end
    end

    test "matches pattern with like statement", %{structs: structs} do
      results = Query.scoped(TestStruct, [type: {:like, "a"}]) |> Repo.all
      assert length(results) == 4

      struct_data = structs
      |> Enum.filter(fn(x) -> x.type == "bar" || x.type == "baz" end)
      |> Enum.map(fn(x) -> Map.take(x, [:name, :type, :value]) end)

      result_data = results
      |> Enum.map(fn(x) -> Map.take(x, [:name, :type, :value]) end)

      for expected <- struct_data do
        assert Enum.member?(result_data, expected)
      end
    end

    test "matches pattern with not like statement", %{structs: structs} do
      results = Query.scoped(TestStruct, [type: {:not_like, "a"}]) |> Repo.all
      assert length(results) == 3

      struct_data = structs
      |> Enum.filter(fn(x) -> x.type == "foo" end)
      |> Enum.map(fn(x) -> Map.take(x, [:name, :type, :value]) end)

      result_data = results
      |> Enum.map(fn(x) -> Map.take(x, [:name, :type, :value]) end)

      for expected <- struct_data do
        assert Enum.member?(result_data, expected)
      end
    end
  end
end
