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
      import SimpleRepo.Query

      @repo Keyword.get(opts, :repo)

      def save(struct, params) do
        struct
        |> changeset(params)
        |> @repo.insert
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

      def destroy(model, id, scope \\ []) do
        {_transaction_status, {status, response}} = @repo.transaction fn ->
          case one(model, id, scope) do
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
