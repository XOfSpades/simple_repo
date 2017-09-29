defmodule SimpleRepo.Query do
  import Ecto.Query
  require Logger

  @moduledoc """
  SimpleRepo.Query provides a possibility to create scoped queries for Ecto:

  SimpleRepo.Query.scoped(scopes)

  Here scopes is a keyword list offering different possibilities to query against a database:

  [

    {key, nil}, # => "where key is nil"

    {key, value}, # => where key is equal to value

    {key, value_list}, # => where key is included in value_list

    {key, {:like, pattern}}, # => where key matches pattern

    {key, {:not, nil}}, # => "where key is not nil"

    {key, {:not, value}}, # => where key is not equal to value

    {key, {:not, value_list}}, # => where key is not included in value_list

    {key, {:not_like, pattern}}, # => where key does not match pattern

    {key, {:<, value}}, # => where key less than value

    {key, {:<=, value}}, # => where key less than or equal value

    {key, {:>, value}}, # => where key greater than value

    {key, {:>=, value}}, # => where key greater than or equal to value

  ]

  Example:

  User |> Query.scoped([last_name: "Smith", age: {:>=, 21}]) |> Repo.all
  """

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
    scope_query(queriable, {key, {:not, [value]}})
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
  defp scope_query(queriable, {key, {:<, value}}) do
    queriable |> where([m], field(m, ^key) < ^value)
  end
  defp scope_query(queriable, {key, {:<=, value}}) do
    queriable |> where([m], field(m, ^key) <= ^value)
  end
  defp scope_query(queriable, {key, {:>, value}}) do
    queriable |> where([m], field(m, ^key) > ^value)
  end
  defp scope_query(queriable, {key, {:>=, value}}) do
    queriable |> where([m], field(m, ^key) >= ^value)
  end
end
