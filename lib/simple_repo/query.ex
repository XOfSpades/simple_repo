defmodule SimpleRepo.Query do
  import Ecto.Query
  require Logger

  def scoped(queriable, scopes) when is_list(scopes) or is_map(scopes) do
    Enum.reduce(
      scopes, queriable, fn(scope, acc) -> acc |> scope_query(scope) end
    )
  end

  defp scope_query(queriable, {key, value}) when is_binary(key) do
    scope_query(queriable, {String.to_existing_atom(key), value})
  end
  defp scope_query(queriable, {key, nil}) do
    from m in queriable, where: is_nil(field(m, ^key))
  end
  defp scope_query(queriable, {key, value})
       when is_binary(value) or is_integer(value) do
    queriable |> where(^[{key, value}])
  end
  defp scope_query(queriable, {key, value}) when is_atom(value) do
    scope_query(queriable, {key, Atom.to_string(value)})
  end
  defp scope_query(queriable, {key, values}) when is_list(values) do
    queriable |> where([m], field(m, ^key) in ^values)
  end
  defp scope_query(queriable, {key, {:not, nil}}) do
    from m in queriable, where: not is_nil(field(m, ^key))
  end
  defp scope_query(queriable, {key, {:not, value}})
       when is_binary(value) or is_integer(value) do
    scope_query(queriable, {key, {:not, [value]}}) # maybe better solution?
  end
  defp scope_query(queriable, {key, {:not, values}}) when is_list(values) do
    queriable |> where([m], not field(m, ^key) in ^values)
  end
  defp scope_query(queriable, {key, {:like, pattern}}) do
    from m in queriable, where: like(field(m, ^key), ^"%#{pattern}%")
  end
  defp scope_query(queriable, {key, {:not_like, pattern}}) do
    from m in queriable, where: not like(field(m, ^key), ^"%#{pattern}%")
  end
end
