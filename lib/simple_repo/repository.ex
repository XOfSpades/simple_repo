defmodule SimpleRepo.Repository do
  @moduledoc """
  SimpleRepo.Repository provides a macro enabling you to create simple database
  interactions. The macro can be used by providing it the Ecto.Repo module:

  defmodule MyRepository do\n
      use SimpleRepo.Repository, repo: MyRepo\n
  end

  The following functions are available: \n
    save/2, one/3, all/2, patch/4, destroy/3, aggregate/4

  You can see the function as a mapping to crud actions:
  create -> save
  update -> patch
  show -> one
  index -> all
  delete -> destroy

  """
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      import Ecto.Query
      require Logger

      @repo Keyword.get(opts, :repo)

      def save(struct, params) do
        struct
        |> changeset(params)
        |> @repo.insert
      end

      def get(model, id, scope \\ []) when is_binary(id) or is_integer(id) do
        Logger.warn("SimpleRepo.Repository.get is depricated. " <>
                    "Use SimpleRepo.Repository.one instead")
        one(model, id, scope)
      end

      def one(model, id, scope \\ []) when is_binary(id) or is_integer(id) do
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

      def revise(model, id, params, scope \\ []) do
        Logger.warn("SimpleRepo.Repository.revise is depricated. " <>
                    "Use SimpleRepo.Repository.patch instead")
        patch(model, id, params, scope)
      end

      def patch(model, id, params, scope \\ []) do
        {_transaction_status, {status, response}} = @repo.transaction fn ->
          case one(model, id, scope) do
            {:error, :not_found} -> not_found()
            {:ok, entity} ->
              entity
              |> changeset(params)
              |> @repo.update
          end
        end
        {status, response}
      end

      def update(model, id, params, scope \\ []) do
        Logger.warn("SimpleRepo.Repository.update is depricated. " <>
                    "Use SimpleRepo.Repository.patch instead")
        patch(model, id, params, scope)
      end

      def destroy(model, id, scope \\ []) do
        {_transaction_status, {status, response}} = @repo.transaction fn ->
          case one(model, id, scope) do
            {:error, :not_found} -> not_found()
            {:ok, entity} -> @repo.delete(entity)
          end
        end
        {status, response}
      end

      def delete(model, id, scope \\ []) do
        Logger.warn("SimpleRepo.Repository.delete is depricated. " <>
                    "Use SimpleRepo.Repository.destroy instead")
        destroy(model, id, scope)
      end

      # aggretagtion_types: [:avg, :count, :max, :min, :sum]
      def aggregate(model, aggregation_type, field, scope \\ []) do
        model
        |> scoped(scope)
        |> @repo.aggregate(aggregation_type, field)
      end

      defp scoped(model, scopes) do
        Enum.reduce(
          scopes, model, fn(scope, acc) -> acc |> scope_query(scope) end
        )
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
      defp scope_query(model, {key, {:not, nil}}) do
        from m in model, where: not is_nil(field(m, ^key))
      end
      defp scope_query(model, {key, {:not, value}})
           when is_binary(value) or is_integer(value) do
        scope_query(model, {key, {:not, [value]}}) # maybe better solution?
      end
      defp scope_query(model, {key, {:not, values}}) when is_list(values) do
        model |> where([m], not field(m, ^key) in ^values)
      end
      defp scope_query(model, {key, {:like, pattern}}) do
        # from m in model, where: like(u.username, ^username)
        from m in model, where: like(field(m, ^key), ^"%#{pattern}%")
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
  end
end
