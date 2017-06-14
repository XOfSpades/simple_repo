defmodule SimpleRepo.RepositoryTest do
  use ExUnit.Case, async: true
  use SimpleRepo.Support.RepoCase
  alias SimpleRepo.Support.TestRepository, as: Repository
  alias SimpleRepo.Support.TestStruct

  setup do
    structs = SimpleRepo.Support.Fixtures.test_structs
    {:ok, structs: structs}
  end

  describe ".save" do
    test "creates a database record when params are valid" do
      params = %{name: "Hula", type: "foo", value: 42}
      struct = %TestStruct{name: "Hula", type: "foo", value: 42}

      {:ok, item} = Repository.save(%TestStruct{}, params)

      assert item.id
      assert item.name == struct.name
      assert item.type == struct.type
      assert item.value == struct.value

      assert Repo.get(TestStruct, item.id) == item
    end

    test "doesn't write data when invalid and returns an error tuple" do
      params = %{name: "Hula", value: 42}

      {:error, msg} = Repository.save(%TestStruct{}, params)

      assert msg
      refute Enum.find(Repo.all(TestStruct), &(&1.name == "Hula"))
    end
  end

  describe ".update" do
    test "updates an item", %{structs: structs} do
      [item|_] = structs
      {:ok, updated_item} =
        Repository.update(TestStruct, item.id, %{name: "Hulahupp"})

      assert updated_item.name == "Hulahupp"
      assert updated_item.type == item.type
      assert updated_item.value == item.value

      assert Repo.get(TestStruct, item.id) == updated_item
    end

    test "does not update when change is invalid", %{structs: structs} do
      [item|_] = structs
      {:error, msg} =
        Repository.update(TestStruct, item.id, %{name: nil})

      assert msg

      assert Repo.get(TestStruct, item.id) == item
    end

    test "returns not found when no such item exists}", %{structs: structs} do
      unknown_id = Enum.max_by(structs, &(&1.id)).id + 1
      result = Repository.update(TestStruct, unknown_id, %{name: "Hulahupp"})

      assert {:error, :not_found} = result
    end
  end

  describe ".get" do
    test "returns the item", %{structs: structs} do
      [item|_] = structs
      assert {:ok, item} == Repository.get(TestStruct, item.id)
    end

    test "returns no item if the id does not match the scope",
         %{structs: structs} do
      [item|_] = structs
      result = Repository.get(TestStruct, item.id, type: "foobar")
      assert {:error, :not_found} == result
    end

    test "returns no item if the id does not exist", %{structs: structs} do
      unknown_id = Enum.max_by(structs, &(&1.id)).id + 1
      assert Repository.get(TestStruct, unknown_id) == {:error, :not_found}
    end
  end

  describe ".all" do
    test "returns all structs", %{structs: structs} do
      assert MapSet.new(Repository.all(TestStruct)) == MapSet.new(structs)
    end

    test "returns structs scoped by a single attribute", %{structs: structs} do
      result = MapSet.new(Repository.all(TestStruct, type: "foo"))
      expected = MapSet.new(Enum.filter(structs, &(&1.type == "foo")))
      assert result == expected
    end

    test "returns structs scoped by multiple attributes", %{structs: structs} do
      result = Repository.all(TestStruct, type: "foo", value: 2)
      expected = MapSet.new(
        Enum.filter(structs, &(&1.type == "foo" && &1.value == 2))
      )
      assert length(result) == 2
      assert MapSet.new(result) == expected
    end

    test "can query nil values", %{structs: structs} do
      result = Repository.all(TestStruct, value: nil)
      expected = Enum.filter(structs, &(&1.value == nil))
      assert result == expected
    end

    test "can query with list scopes", %{structs: structs} do
      result = Repository.all(TestStruct, type: ["foo", "bar"])
      expected = Enum.filter(structs, &(&1.type == "foo" || &1.type == "bar"))
      assert MapSet.new(result) == MapSet.new(expected)
    end
  end

  describe ".delete" do
    test "deletes an item", %{structs: structs} do
      [item|_] = structs
      Repository.delete(TestStruct, item.id)
      refute SimpleRepo.Support.Repo.get(TestStruct, item.id)
    end

    test "does not delete when item is not in scope", %{structs: structs} do
      [item|_] = structs
      Repository.delete(TestStruct, item.id, type: :foobar)
      assert SimpleRepo.Support.Repo.get(TestStruct, item.id)
    end
  end

  describe ".aggregate" do
    test "returns the count of items", %{structs: structs} do
      assert length(structs) == Repository.aggregate(TestStruct, :count, :id)
    end

    test "returns the count of items in scope" do
      assert 3 == Repository.aggregate(TestStruct, :count, :id, type: :foo)
    end
  end
end
