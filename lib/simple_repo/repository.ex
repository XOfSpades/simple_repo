defmodule SimpleRepo.Repository do
  require Logger
  import Ecto.Query

  @repo Application.get_env(:simple_repo, :repo)[:module_name]

  def save(struct, params) do
    struct
    |> changeset(params)
    |> @repo.insert
  end

  def get(model, id, scope \\ []) when is_binary(id) or is_integer(id) do
    model
    |> scoped(scope)
    |> @repo.get(id)
    |> entity_result
  end

  def all(model, scope \\ []) do
    model
    |> scoped(scope)
    |> @repo.all()
  end

  def update(model, id, params, scope \\ []) do
    {_transaction_status, {status, response}} = @repo.transaction fn ->
      case get(model, id, scope) do
        {:error, :not_found} -> not_found()
        {:ok, entity} ->
          entity
          |> changeset(params)
          |> @repo.update
      end
    end
    {status, response}
  end

  def delete(model, id, scope \\ []) do
    {_transaction_status, {status, response}} = @repo.transaction fn ->
      case get(model, id, scope) do
        {:error, :not_found} -> not_found()
        {:ok, entity} -> @repo.delete(entity)
      end
    end
    {status, response}
  end

  # aggretagtion_types: [:avg, :count, :max, :min, :sum]
  def aggregate(model, aggregation_type, field, scope \\ []) do
    model
    |> scoped(scope)
    |> @repo.aggregate(aggregation_type, field)
  end

  defp scoped(model, scopes) do
    Enum.reduce(scopes, model, fn(scope, acc) -> acc |> scope_query(scope) end)
  end

  defp scope_query(model, {key, nil}) do
    from m in model, where: is_nil(field(m, ^key))
  end
  defp scope_query(model, {key, value})
       when is_binary(value) or is_integer(value) do
    model |> where(^[{key, value}])
  end
  defp scope_query(model, {key, value}) when is_atom(value) do
    scope_query(model, {key, Atom.to_string(value)})
  end
  defp scope_query(model, {key, values}) when is_list(values) do
    model |> where([m], field(m, ^key) in ^values)
  end

  defp entity_result(response) do
    case response do
      nil -> not_found()
      entity -> {:ok, entity}
    end
  end

  defp not_found, do: {:error, :not_found}

  defp repo, do: Application.get_env(:simple_repo, :repo)[:module_name]

  defp changeset(struct, params) do
    struct.__struct__.changeset(struct, params)
  end
end
