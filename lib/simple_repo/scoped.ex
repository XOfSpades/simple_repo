defmodule SimpleRepo.Scoped do
  @moduledoc """
  SimpleRepo.Scoped provides a macro extending the Ecto.Repo module:

  defmodule MyRepository do\n
    use Ecto.Repo, otp_app: :my_app
    use SimpleRepo.Scoped, repo: __MODULE__
  end

  The following functions are available: \n
    by_id_scoped/4
    one_scoped/3,
    all_scoped/2,
    update_scoped/5,
    update_all_scoped/4
    delete_scoped/4,
    delete_all_scoped/3
    aggregate_scoped/5

  The scope will ensure only access to conditions defined as scope given by a
  keyword list.

  The scopes corresponds to everythng valid from SimpleRepo.Query
  """
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      import Ecto.Query
      require Logger
      import SimpleRepo.Query

      @repo Keyword.get(opts, :repo)

      def by_id_scoped(model, id, scope, opts \\ [])
          when is_binary(id) or is_integer(id) do
        model
        |> scoped(scope)
        |> @repo.get(id, opts)
        |> entity_result
      end

      def one_scoped(model, scope, opts \\ []) do
        model
        |> scoped(scope)
        |> @repo.one(opts)
        |> entity_result
      end

      def all_scoped(model, scope, opts \\ []) do
        model
        |> scoped(scope)
        |> order(opts)
        |> @repo.all(opts)
      end

      def update_scoped(model, id, params, scope, opts \\ []) do
        {_transaction_status, {status, response}} = @repo.transaction fn ->
          case by_id_scoped(model, id, scope, opts) do
            {:error, :not_found} -> not_found()
            {:ok, entity} ->
              entity
              |> changeset(params)
              |> @repo.update
          end
        end
        {status, response}
      end

      def update_all_scoped(model, params, scope, opts \\ []) do
        model
        |> scoped(scope)
        |> @repo.update_all(params, opts)
      end

      def delete_scoped(model, id, scope, opts \\ []) do
        {_transaction_status, {status, response}} = @repo.transaction fn ->
          case by_id_scoped(model, id, scope, opts) do
            {:error, :not_found} -> not_found()
            {:ok, entity} -> @repo.delete(entity)
          end
        end
        {status, response}
      end

      def delete_all_scoped(model, scope, opts \\ []) do
        model
        |> scoped(scope)
        |> @repo.delete_all(opts)
      end

      # aggretagtion_types: [:avg, :count, :max, :min, :sum]
      def aggregate_scoped(model, aggregation_type, field, scope, opts \\ []) do
        model
        |> scoped(scope)
        |> @repo.aggregate(aggregation_type, field, opts)
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

      defp order(queriable, opts) do
        case Keyword.get(opts, :order_by, nil) do
          nil -> queriable
          ordering -> ordered(queriable, ordering)
        end
      end
    end
  end
end
