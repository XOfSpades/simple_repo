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
      test_struct =
        TestStruct
        |> Repo.all()
        |> Enum.filter(& &1.some_time)
        |> Enum.random()
      query_result = TestStruct
      |> Query.scoped([some_time: test_struct.some_time])
      |> Repo.all()

      assert length(query_result) > 0

      assert Enum.all?(
        query_result,
        fn item ->
          NaiveDateTime.compare(
            test_struct.some_time, item.some_time
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

    test "scopes to a negated NaiveDateTime" do
      test_struct =
        TestStruct
        |> Repo.all()
        |> Enum.filter(& &1.some_time)
        |> Enum.random()
      query_result = TestStruct
      |> Query.scoped([some_time: {:not, test_struct.some_time}])
      |> Repo.all()

      assert length(query_result) > 0

      assert Enum.all?(
        query_result,
        fn item ->
          NaiveDateTime.compare(
            test_struct.some_time, item.some_time
          ) != :eq
        end
      )
    end

    test "scopes to items having a higher NaiveDateTime" do
      test_struct =
        TestStruct
        |> Repo.all()
        |> Enum.filter(& &1.some_time)
        |> Enum.random()
      query_result = TestStruct
      |> Query.scoped([some_time: {:>, test_struct.some_time}])
      |> Repo.all()

      assert Enum.all?(
        query_result,
        fn item ->
          NaiveDateTime.compare(
            test_struct.some_time, item.some_time
          ) == :lt
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

    test "scopes to items included in a list when it is binary type", %{structs: structs} do
      [_, _, _ | expected] = Enum.shuffle(structs)
      uuids = Enum.map(expected, fn s -> s.uuid end)

      results = TestStruct
      |> Query.scoped([uuid: uuids])
      |> Repo.all

      assert length(results) == length(expected)

      struct_data = expected
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

  describe "jsonb queries" do
    test "finds with specific key value pairs", %{structs: structs} do
      results = TestStruct
      |> Query.scoped([{:jsonb, {:json, {"foo", "hurz"}}}])
      |> Repo.all()

      result_data = results
      |> Enum.map(fn(x) ->
        Map.take(x, [:name, :type, :value, :f_value, :jsonb])
      end)

      expected = structs
      |> Enum.filter(fn s ->
        !is_nil(s.jsonb) && Map.get(s.jsonb, "foo") == "hurz"
      end)
      |> Enum.map(fn(x) ->
        Map.take(x, [:name, :type, :value, :f_value, :jsonb])
      end)

      assert length(results) == 1
      assert result_data == expected
    end

    test "finds with nested keys a specific value", %{structs: structs} do
      results = TestStruct
      |> Query.scoped([{:jsonb, {:json, {["baz", "boom"], 42}}}])
      |> Repo.all()

      result_data = results
      |> Enum.map(fn(x) ->
        Map.take(x, [:name, :type, :value, :f_value, :jsonb])
      end)

      expected = structs
      |> Enum.filter(fn s ->
        !is_nil(s.jsonb) && get_in(s.jsonb, ["baz", "boom"]) == 42
      end)
      |> Enum.map(fn(x) ->
        Map.take(x, [:name, :type, :value, :f_value, :jsonb])
      end)

      assert length(results) == 2
      assert MapSet.new(result_data) == MapSet.new(expected)
    end

    test "finds with nested atom keys a specific value", %{structs: structs} do
      results = TestStruct
      |> Query.scoped([{:jsonb, {:json, {[:baz, :boom], 42}}}])
      |> Repo.all()

      result_data = results
      |> Enum.map(fn(x) ->
        Map.take(x, [:name, :type, :value, :f_value, :jsonb])
      end)

      expected = structs
      |> Enum.filter(fn s ->
        !is_nil(s.jsonb) && get_in(s.jsonb, ["baz", "boom"]) == 42
      end)
      |> Enum.map(fn(x) ->
        Map.take(x, [:name, :type, :value, :f_value, :jsonb])
      end)

      assert length(results) == 2
      assert MapSet.new(result_data) == MapSet.new(expected)
    end

    test "finds key with boolean value", %{structs: structs} do
      results = TestStruct
      |> Query.scoped([{:jsonb, {:json, {"foo", true}}}])
      |> Repo.all()

      result_data = results
      |> Enum.map(fn(x) ->
        Map.take(x, [:name, :type, :value, :f_value, :jsonb])
      end)

      expected = structs
      |> Enum.filter(fn s ->
        !is_nil(s.jsonb) && Map.get(s.jsonb, "foo") == true
      end)
      |> Enum.map(fn(x) ->
        Map.take(x, [:name, :type, :value, :f_value, :jsonb])
      end)

      assert length(results) == 1
      assert MapSet.new(result_data) == MapSet.new(expected)
    end

    test "finds nested key with boolean value", %{structs: structs} do
      results = TestStruct
      |> Query.scoped([{:jsonb, {:json, {["answer", 42], true}}}])
      |> Repo.all()

      result_data = results
      |> Enum.map(fn(x) ->
        Map.take(x, [:name, :type, :value, :f_value, :jsonb])
      end)

      expected = structs
      |> Enum.filter(fn s ->
        !is_nil(s.jsonb) && Map.get(s.jsonb, "answer") == %{"42" => true}
      end)
      |> Enum.map(fn(x) ->
        Map.take(x, [:name, :type, :value, :f_value, :jsonb])
      end)

      assert length(results) == 1
      assert MapSet.new(result_data) == MapSet.new(expected)
    end

    test "finds entities with > operator", %{structs: structs} do
      results = TestStruct
      |> Query.scoped([{:jsonb, {:json, {["baz", "boom"], :>, 43}}}])
      |> Repo.all()

      result_data = results
      |> Enum.map(fn(x) ->
        Map.take(x, [:name, :type, :value, :f_value, :jsonb])
      end)

      expected = structs
      |> Enum.filter(fn s ->
        !is_nil(s.jsonb) &&
        !is_nil(get_in(s.jsonb, ["baz", "boom"])) &&
        get_in(s.jsonb, ["baz", "boom"]) > 43
      end)
      |> Enum.map(fn(x) ->
        Map.take(x, [:name, :type, :value, :f_value, :jsonb])
      end)

      assert length(results) == 1
      assert MapSet.new(result_data) == MapSet.new(expected)
    end

    test "finds entities with < operator", %{structs: structs} do
      results = TestStruct
      |> Query.scoped([{:jsonb, {:json, {["baz", "boom"], :<, 43}}}])
      |> Repo.all()

      result_data = results
      |> Enum.map(fn(x) ->
        Map.take(x, [:name, :type, :value, :f_value, :jsonb])
      end)

      expected = structs
      |> Enum.filter(fn s ->
        !is_nil(s.jsonb) &&
        !is_nil(get_in(s.jsonb, ["baz", "boom"])) &&
        get_in(s.jsonb, ["baz", "boom"]) < 43
      end)
      |> Enum.map(fn(x) ->
        Map.take(x, [:name, :type, :value, :f_value, :jsonb])
      end)

      assert length(results) == 2
      assert MapSet.new(result_data) == MapSet.new(expected)
    end

    test "finds entities with >= operator", %{structs: structs} do
      results = TestStruct
      |> Query.scoped([{:jsonb, {:json, {["baz", "boom"], :>=, 43}}}])
      |> Repo.all()

      result_data = results
      |> Enum.map(fn(x) ->
        Map.take(x, [:name, :type, :value, :f_value, :jsonb])
      end)

      expected = structs
      |> Enum.filter(fn s ->
        !is_nil(s.jsonb) &&
        !is_nil(get_in(s.jsonb, ["baz", "boom"])) &&
        get_in(s.jsonb, ["baz", "boom"]) >= 43
      end)
      |> Enum.map(fn(x) ->
        Map.take(x, [:name, :type, :value, :f_value, :jsonb])
      end)

      assert length(results) == 2
      assert MapSet.new(result_data) == MapSet.new(expected)
    end

    test "finds entities with <= operator", %{structs: structs} do
      results = TestStruct
      |> Query.scoped([{:jsonb, {:json, {["baz", "boom"], :<=, 43}}}])
      |> Repo.all()

      result_data = results
      |> Enum.map(fn(x) ->
        Map.take(x, [:name, :type, :value, :f_value, :jsonb])
      end)

      expected = structs
      |> Enum.filter(fn s ->
        !is_nil(s.jsonb) &&
        !is_nil(get_in(s.jsonb, ["baz", "boom"])) &&
        get_in(s.jsonb, ["baz", "boom"]) <= 43
      end)
      |> Enum.map(fn(x) ->
        Map.take(x, [:name, :type, :value, :f_value, :jsonb])
      end)

      assert length(results) == 3
      assert MapSet.new(result_data) == MapSet.new(expected)
    end

    test "finds entities with LIKE operator", %{structs: structs} do
      results = TestStruct
      |> Query.scoped([{:jsonb, {:json, {"foo", :like, "%a%"}}}])
      |> Repo.all()

      result_data = results
      |> Enum.map(fn(x) ->
        Map.take(x, [:name, :type, :value, :f_value, :jsonb])
      end)

      expected = structs
      |> Enum.filter(fn s ->
        !is_nil(s.jsonb) &&
        !is_nil(Map.get(s.jsonb, "foo")) &&
        (Map.get(s.jsonb, "foo") == "bar" || Map.get(s.jsonb, "foo") == "bam")
      end)
      |> Enum.map(fn(x) ->
        Map.take(x, [:name, :type, :value, :f_value, :jsonb])
      end)

      assert length(results) == 3
      assert MapSet.new(result_data) == MapSet.new(expected)
    end

    test "finds entities with NOT LIKE operator", %{structs: structs} do
      results = TestStruct
      |> Query.scoped([{:jsonb, {:json, {"foo", :not_like, "%a%"}}}])
      |> Repo.all()

      result_data = results
      |> Enum.map(fn(x) ->
        Map.take(x, [:name, :type, :value, :f_value, :jsonb])
      end)

      expected = structs
      |> Enum.filter(fn s ->
        !is_nil(s.jsonb) &&
        !is_nil(Map.get(s.jsonb, "foo")) &&
        (Map.get(s.jsonb, "foo") != "bar" && Map.get(s.jsonb, "foo") != "bam")
      end)
      |> Enum.map(fn(x) ->
        Map.take(x, [:name, :type, :value, :f_value, :jsonb])
      end)

      assert length(results) == 2
      assert MapSet.new(result_data) == MapSet.new(expected)
    end

    test "finds entities with IN operator", %{structs: structs} do
      results1 = TestStruct
      |> Query.scoped([{:jsonb, {:json, {"foo", ["bar", "bam"]}}}])
      |> Repo.all()
      |> Enum.map(fn(x) ->
        Map.take(x, [:name, :type, :value, :f_value, :jsonb])
      end)

      results2 = TestStruct
      |> Query.scoped([{:jsonb, {:json, {"foo", ["bar", "bam"]}}}])
      |> Repo.all()
      |> Enum.map(fn(x) ->
        Map.take(x, [:name, :type, :value, :f_value, :jsonb])
      end)

      expected = structs
      |> Enum.filter(fn s ->
        !is_nil(s.jsonb) &&
        !is_nil(Map.get(s.jsonb, "foo")) &&
        (Map.get(s.jsonb, "foo") == "bar" || Map.get(s.jsonb, "foo") == "bam")
      end)
      |> Enum.map(fn(x) ->
        Map.take(x, [:name, :type, :value, :f_value, :jsonb])
      end)

      assert length(results1) == 3
      assert MapSet.new(results1) == MapSet.new(results2)
      assert MapSet.new(results1) == MapSet.new(expected)
    end

    test "finds entities with NOT IN operator", %{structs: structs} do
      results = TestStruct
      |> Query.scoped([{:jsonb, {:json, {"foo", :not_in, ["bar", "bam"]}}}])
      |> Repo.all()

      result_data = results
      |> Enum.map(fn(x) ->
        Map.take(x, [:name, :type, :value, :f_value, :jsonb])
      end)

      expected = structs
      |> Enum.filter(fn s ->
        !is_nil(s.jsonb) &&
        !is_nil(Map.get(s.jsonb, "foo")) &&
        (Map.get(s.jsonb, "foo") != "bar" && Map.get(s.jsonb, "foo") != "bam")
      end)
      |> Enum.map(fn(x) ->
        Map.take(x, [:name, :type, :value, :f_value, :jsonb])
      end)

      assert length(results) == 2
      assert MapSet.new(result_data) == MapSet.new(expected)
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
