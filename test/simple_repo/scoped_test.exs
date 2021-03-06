defmodule SimpleRepo.RepositoryTest do
  use ExUnit.Case, async: true
  use SimpleRepo.Support.RepoCase
  alias SimpleRepo.Support.TestStruct
  alias SimpleRepo.Support.Repo

  setup do
    structs = SimpleRepo.Support.Fixtures.test_structs
    {:ok, structs: structs}
  end

  describe ".update_scoped" do
    test "updates an item", %{structs: structs} do
      [item|_] = structs
      {:ok, updated_item} =
        Repo.update_scoped(TestStruct, item.id, %{name: "Yay"}, [type: "foo"])

      assert updated_item.name == "Yay"
      assert updated_item.type == item.type
      assert updated_item.value == item.value

      assert Repo.get(TestStruct, item.id) == updated_item
    end

    test "does not update when change is invalid", %{structs: structs} do
      [item|_] = structs
      {:error, msg} =
        Repo.update_scoped(TestStruct, item.id, %{name: nil}, [type: "foo"])

      assert msg

      assert Repo.get(TestStruct, item.id) == item
    end

    test "return not found when no such item exists}", %{structs: structs} do
      unknown_id = Enum.max_by(structs, &(&1.id)).id + 1
      result =
        Repo.update_scoped(TestStruct, unknown_id, %{name: "Hulahupp"}, [])

      assert {:error, :not_found} = result
    end

    test "not update unscoped item", %{structs: structs} do
      [item|_] = structs
      response =
        Repo.update_scoped(TestStruct, item.id, %{name: "Yay"}, [type: "bar"])

      assert response == {:error, :not_found}
      assert Repo.get(TestStruct, item.id) == item
    end
  end

  describe ".update_all_scoped" do
    test "updates all items in scopes and returns them", %{structs: structs} do
      items = Enum.filter(structs, &(&1.type == "foo"))
      {count, updated_items} = Repo.update_all_scoped(
        from(ts in TestStruct, select: ts), [set: [type: "yay"]], [type: "foo"]
      )

      assert count == length(items)

      Enum.each(items, fn item ->
        db_item = Repo.get(TestStruct, item.id)
        assert db_item
        assert db_item.type == "yay"
        assert Map.delete(item, :type) == Map.delete(db_item, :type)
        assert Enum.member?(updated_items, db_item)
      end)

      yay_items = TestStruct |> Ecto.Query.where(type: "yay") |> Repo.all
      assert length(yay_items) == length(updated_items)
    end

    test "raises an exception when params are invalid", %{structs: structs} do
      items = Enum.filter(structs, &(&1.type == "foo"))
      assert_raise(
        Postgrex.Error,
        fn ->
          Repo.update_all_scoped(TestStruct, [set: [type: nil]], [type: "foo"])
        end
      )

      Enum.each(items, fn item ->
        db_item = Repo.get(TestStruct, item.id)
        assert db_item
        assert item == db_item
      end)
    end
  end

  describe ".by_id_scoped" do
    test "return the item in scope", %{structs: structs} do
      [item|_] = structs
      %{id: id, type: type} = item
      assert {:ok, item} == Repo.by_id_scoped(TestStruct, id, type: type)
    end

    test "return {:error, :not_found} when not in scope", %{structs: structs} do
      [item|_] = structs
      result = Repo.by_id_scoped(TestStruct, item.id, type: "foobar")
      assert {:error, :not_found} == result
    end
  end

  describe ".one_scoped" do
    test "return the item", %{structs: structs} do
      [item|_] = structs
      assert {:ok, item} == Repo.one_scoped(TestStruct, name: item.name)
    end

    test "return no item if nothing is in scope" do
      result = Repo.one_scoped(TestStruct, type: "foobar")
      assert {:error, :not_found} == result
    end

    test "raises an error if more items are in scope" do
      assert_raise(
        Ecto.MultipleResultsError,
        fn -> Repo.one_scoped(TestStruct, type: "foo") end
      )
    end
  end

  describe ".all_scoped" do
    test "return structs scoped by a single attribute", %{structs: structs} do
      result = MapSet.new(Repo.all_scoped(TestStruct, type: "foo"))
      expected = MapSet.new(Enum.filter(structs, &(&1.type == "foo")))
      assert result == expected
    end

    test "return structs scoped by multiple attributes", %{structs: structs} do
      result = Repo.all_scoped(TestStruct, type: "foo", value: 2)
      expected = MapSet.new(
        Enum.filter(structs, &(&1.type == "foo" && &1.value == 2))
      )
      assert length(result) == 2
      assert MapSet.new(result) == expected
    end

    test "can query nil values", %{structs: structs} do
      result = Repo.all_scoped(TestStruct, value: nil)
      expected = Enum.filter(structs, &(&1.value == nil))
      assert result == expected
    end

    test "can query with list scopes", %{structs: structs} do
      result = Repo.all_scoped(TestStruct, type: ["foo", "bar"])
      expected = Enum.filter(structs, &(&1.type == "foo" || &1.type == "bar"))
      assert MapSet.new(result) == MapSet.new(expected)
    end

    test "supports ordering via opts", %{structs: structs} do
      ordering = fn item1, item2 ->
        if item1.f_value == item2.f_value do
          item1.name > item2.name
        else
          item1.f_value < item2.f_value
        end
      end

      result = Repo.all_scoped(
        TestStruct,
        [type: ["foo", "baz"]],
        [order_by: [{:f_value, :asc}, {:name, :desc}]]
      )

      expected = structs
      |> Enum.filter(&(&1.type == "foo" || &1.type == "baz"))
      |> Enum.sort(ordering)

      assert result == expected
    end
  end

  describe ".delete_scoped" do
    test "deletes an item in scope", %{structs: structs} do
      [item|_] = structs
      Repo.delete_scoped(TestStruct, item.id, type: item.type)
      refute SimpleRepo.Support.Repo.get(TestStruct, item.id)
    end

    test "does not delete when item is not in scope", %{structs: structs} do
      [item|_] = structs
      Repo.delete_scoped(TestStruct, item.id, type: :foobar)
      assert SimpleRepo.Support.Repo.get(TestStruct, item.id)
    end
  end

  describe ".aggregate_scoped" do
    test "return the count of items", %{structs: structs} do
      count = Repo.aggregate_scoped(TestStruct, :count, :id, type: "foo")
      assert count == length(Enum.filter(structs, &(&1.type == "foo")))
    end
  end
end
