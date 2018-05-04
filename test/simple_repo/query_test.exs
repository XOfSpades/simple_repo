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
      |> Enum.map(fn(x) -> Map.take(x, [:name, :type, :value, :f_value]) end)

      result_data = results
      |> Enum.map(fn(x) -> Map.take(x, [:name, :type, :value, :f_value]) end)

      for expected <- struct_data do
        assert Enum.member?(result_data, expected)
      end
    end

    test "allows any kind of tuple enum", %{structs: structs} do
      results = Query.scoped(TestStruct, [{"type", "foo"}]) |> Repo.all
      assert length(results) == 3

      struct_data = structs
      |> Enum.filter(fn(x) -> x.type == "foo" end)
      |> Enum.map(fn(x) -> Map.take(x, [:name, :type, :value, :f_value]) end)

      result_data = results
      |> Enum.map(fn(x) -> Map.take(x, [:name, :type, :value, :f_value]) end)

      for expected <- struct_data do
        assert Enum.member?(result_data, expected)
      end
    end

    test "scoped to a single nil value", %{structs: structs} do
      results = Query.scoped(TestStruct, [value: nil]) |> Repo.all
      assert length(results) == 1

      struct_data = structs
      |> Enum.filter(fn(x) -> is_nil(x.value) end)
      |> Enum.map(fn(x) -> Map.take(x, [:name, :type, :value, :f_value]) end)

      result_data = results
      |> Enum.map(fn(x) -> Map.take(x, [:name, :type, :value, :f_value]) end)

      for expected <- struct_data do
        assert Enum.member?(result_data, expected)
      end
    end

    test "scoped to a single atom value", %{structs: structs} do
      results = Query.scoped(TestStruct, [type: :foo]) |> Repo.all
      assert length(results) == 3

      struct_data = structs
      |> Enum.filter(fn(x) -> x.type == "foo" end)
      |> Enum.map(fn(x) -> Map.take(x, [:name, :type, :value, :f_value]) end)

      result_data = results
      |> Enum.map(fn(x) -> Map.take(x, [:name, :type, :value, :f_value]) end)

      for expected <- struct_data do
        assert Enum.member?(result_data, expected)
      end
    end

    test "scopes to specific NaiveDateTime element" do
      test_struct = TestStruct |> Repo.all() |> Enum.random()
      query_result = TestStruct
      |> Query.scoped([inserted_at: test_struct.inserted_at])
      |> Repo.all()

      assert length(query_result) > 0

      assert Enum.all?(
        query_result,
        fn item ->
          NaiveDateTime.compare(
            test_struct.inserted_at, item.inserted_at
          ) == :eq
        end
      )
    end

    test "scopes to items not equal to value", %{structs: structs} do
      results1 = Query.scoped(TestStruct, [type: {:not, "foo"}]) |> Repo.all
      assert length(results1) == 4

      struct_data1 = structs
      |> Enum.filter(fn(x) -> x.type != "foo" end)
      |> Enum.map(fn(x) -> Map.take(x, [:name, :type, :value, :f_value]) end)

      result_data1 = results1
      |> Enum.map(fn(x) -> Map.take(x, [:name, :type, :value, :f_value]) end)

      for expected <- struct_data1 do
        assert Enum.member?(result_data1, expected)
      end

      results2 = Query.scoped(TestStruct, [f_value: {:not, 42.2}]) |> Repo.all
      assert length(results2) == 3

      struct_data2 = structs
      |> Enum.filter(fn(x) -> x.f_value != 42.2 && !is_nil(x.f_value) end)
      |> Enum.map(fn(x) -> Map.take(x, [:name, :type, :value, :f_value]) end)

      result_data2 = results2
      |> Enum.map(fn(x) -> Map.take(x, [:name, :type, :value, :f_value]) end)

      for expected <- struct_data2 do
        assert Enum.member?(result_data2, expected)
      end
    end

    test "scopes to valie different to a specific NaiveDateTime" do
      test_struct = TestStruct |> Repo.all() |> Enum.random()
      query_result = TestStruct
      |> Query.scoped([inserted_at: {:not, test_struct.inserted_at}])
      |> Repo.all()

      assert length(query_result) > 0

      assert Enum.all?(
        query_result,
        fn item ->
          NaiveDateTime.compare(
            test_struct.inserted_at, item.inserted_at
          ) != :eq
        end
      )
    end

    test "scopes to items equal to float value", %{structs: structs} do
      results = Query.scoped(TestStruct, [f_value: 42.2]) |> Repo.all
      assert length(results) == 2

      struct_data = structs
      |> Enum.filter(fn(x) -> x.f_value == 42.2 end)
      |> Enum.map(fn(x) -> Map.take(x, [:name, :type, :value, :f_value]) end)

      result_data = results
      |> Enum.map(fn(x) -> Map.take(x, [:name, :type, :value, :f_value]) end)

      for expected <- struct_data do
        assert Enum.member?(result_data, expected)
      end
    end

    test "scopes to items with non-nil field", %{structs: structs} do
      results = Query.scoped(TestStruct, [value: {:not, nil}]) |> Repo.all
      assert length(results) == 6

      struct_data = structs
      |> Enum.filter(fn(x) -> x.value end)
      |> Enum.map(fn(x) -> Map.take(x, [:name, :type, :value, :f_value]) end)

      result_data = results
      |> Enum.map(fn(x) -> Map.take(x, [:name, :type, :value, :f_value]) end)

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
      |> Enum.map(fn(x) -> Map.take(x, [:name, :type, :value, :f_value]) end)

      result_data = results
      |> Enum.map(fn(x) -> Map.take(x, [:name, :type, :value, :f_value]) end)

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
      |> Enum.map(fn(x) -> Map.take(x, [:name, :type, :value, :f_value]) end)

      result_data = results
      |> Enum.map(fn(x) -> Map.take(x, [:name, :type, :value, :f_value]) end)

      for expected <- struct_data do
        assert Enum.member?(result_data, expected)
      end
    end

    test "matches pattern with like statement", %{structs: structs} do
      results = Query.scoped(TestStruct, [type: {:like, "%a%"}]) |> Repo.all
      assert length(results) == 4

      struct_data = structs
      |> Enum.filter(fn(x) -> x.type == "bar" || x.type == "baz" end)
      |> Enum.map(fn(x) -> Map.take(x, [:name, :type, :value, :f_value]) end)

      result_data = results
      |> Enum.map(fn(x) -> Map.take(x, [:name, :type, :value, :f_value]) end)

      for expected <- struct_data do
        assert Enum.member?(result_data, expected)
      end
    end

    test "matches pattern with not like statement", %{structs: structs} do
      results = Query.scoped(TestStruct, [type: {:not_like, "%a%"}]) |> Repo.all
      assert length(results) == 3

      struct_data = structs
      |> Enum.filter(fn(x) -> x.type == "foo" end)
      |> Enum.map(fn(x) -> Map.take(x, [:name, :type, :value, :f_value]) end)

      result_data = results
      |> Enum.map(fn(x) -> Map.take(x, [:name, :type, :value, :f_value]) end)

      for expected <- struct_data do
        assert Enum.member?(result_data, expected)
      end
    end

    test "offer a < operator for scopes", %{structs: structs} do
      results = Query.scoped(TestStruct, [value: {:<, 4}]) |> Repo.all
      assert length(results) == 3

      struct_data = structs
      |> Enum.filter(fn(x) -> !is_nil(x.value) && x.value < 4 end)
      |> Enum.map(fn(x) -> Map.take(x, [:name, :type, :value, :f_value]) end)

      result_data = results
      |> Enum.map(fn(x) -> Map.take(x, [:name, :type, :value, :f_value]) end)

      for expected <- struct_data do
        assert Enum.member?(result_data, expected)
      end
    end

    test "offer a <= operator for scopes", %{structs: structs} do
      results = Query.scoped(TestStruct, [value: {:<=, 3}]) |> Repo.all
      assert length(results) == 3

      struct_data = structs
      |> Enum.filter(fn(x) -> !is_nil(x.value) && x.value <= 3 end)
      |> Enum.map(fn(x) -> Map.take(x, [:name, :type, :value, :f_value]) end)

      result_data = results
      |> Enum.map(fn(x) -> Map.take(x, [:name, :type, :value, :f_value]) end)

      for expected <- struct_data do
        assert Enum.member?(result_data, expected)
      end
    end

    test "offer a > operator for scopes", %{structs: structs} do
      results = Query.scoped(TestStruct, [value: {:>, 3}]) |> Repo.all
      assert length(results) == 3

      struct_data = structs
      |> Enum.filter(fn(x) -> !is_nil(x.value) && x.value > 3 end)
      |> Enum.map(fn(x) -> Map.take(x, [:name, :type, :value, :f_value]) end)

      result_data = results
      |> Enum.map(fn(x) -> Map.take(x, [:name, :type, :value, :f_value]) end)

      for expected <- struct_data do
        assert Enum.member?(result_data, expected)
      end
    end

    test "offer a >= operator for scopes", %{structs: structs} do
      results = Query.scoped(TestStruct, [value: {:>=, 4}]) |> Repo.all
      assert length(results) == 3

      struct_data = structs
      |> Enum.filter(fn(x) -> !is_nil(x.value) && x.value >= 4 end)
      |> Enum.map(fn(x) -> Map.take(x, [:name, :type, :value, :f_value]) end)

      result_data = results
      |> Enum.map(fn(x) -> Map.take(x, [:name, :type, :value, :f_value]) end)

      for expected <- struct_data do
        assert Enum.member?(result_data, expected)
      end
    end
  end

  describe ".ordered" do
    test "order desc with one conditions", %{structs: structs} do
      results = TestStruct
      |> Query.ordered({:name, :desc})
      |> Repo.all

      result_data = results
      |> Enum.map(fn(x) -> Map.take(x, [:name, :type, :value, :f_value]) end)

      expected = structs
      |> Enum.sort(&(&1.name >= &2.name))
      |> Enum.map(fn(x) -> Map.take(x, [:name, :type, :value, :f_value]) end)

      assert result_data == expected
    end

    test "order asc with one conditions", %{structs: structs} do
      results = TestStruct
      |> Query.ordered({:name, :asc})
      |> Repo.all

      result_data = results
      |> Enum.map(fn(x) -> Map.take(x, [:name, :type, :value, :f_value]) end)

      expected = structs
      |> Enum.sort(&(&1.name <= &2.name))
      |> Enum.map(fn(x) -> Map.take(x, [:name, :type, :value, :f_value]) end)

      assert result_data == expected
    end

    test "order desc with two conditions", %{structs: structs} do
      results = TestStruct
      |> Query.ordered([{:f_value, :desc}, {:name, :desc}])
      |> Repo.all

      result_data = results
      |> Enum.map(fn(x) -> Map.take(x, [:name, :type, :value, :f_value]) end)

      expected = structs
      |> Enum.sort(&order_desc/2)
      |> Enum.map(fn(x) -> Map.take(x, [:name, :type, :value, :f_value]) end)

      assert result_data == expected
    end

    test "order asc with two conditions", %{structs: structs} do
      results = TestStruct
      |> Query.ordered([{:f_value, :asc}, {:name, :asc}])
      |> Repo.all

      result_data = results
      |> Enum.map(fn(x) -> Map.take(x, [:name, :type, :value, :f_value]) end)

      expected = structs
      |> Enum.sort(&order_asc/2)
      |> Enum.map(fn(x) -> Map.take(x, [:name, :type, :value, :f_value]) end)

      assert result_data == expected
    end
  end

  defp order_desc(item1, item2) do
    if item1.f_value == item2.f_value do
      item1.name > item2.name
    else
      item1.f_value > item2.f_value
    end
  end

  defp order_asc(item1, item2) do
    if item1.f_value == item2.f_value do
      item1.name < item2.name
    else
      item1.f_value < item2.f_value
    end
  end
end
