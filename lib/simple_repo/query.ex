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

  def ordered(queriable, {key, direction})
      when direction == :desc or direction == :asc do
    from m in queriable, order_by: [{^direction, ^key}]
  end
  def ordered(queriable, order_list) do
    order = Enum.map(order_list, fn {key, direction} -> {direction, key} end)
    from m in queriable, order_by: ^order
  end

  defp scope_query(queriable, {key, value}) when is_binary(key) do
    scope_query(queriable, {String.to_existing_atom(key), value})
  end
  defp scope_query(queriable, {key, nil}) do
    from m in queriable, where: is_nil(field(m, ^key))
  end
  defp scope_query(queriable, {key, value}) when is_atom(value) do
    scope_query(queriable, {key, Atom.to_string(value)})
  end
  defp scope_query(queriable, {key, value})
       when not is_list(value) and not is_tuple(value) do
    queriable |> where(^[{key, value}])
  end
  defp scope_query(queriable, {key, values}) when is_list(values) do
    queriable |> where([m], field(m, ^key) in ^values)
  end
  defp scope_query(queriable, {key, {:not, nil}}) do
    from m in queriable, where: not is_nil(field(m, ^key))
  end
  defp scope_query(queriable, {key, {:not, value}})
       when not is_list(value) and not is_tuple(value) do
    scope_query(queriable, {key, {:not, [value]}})
  end
  defp scope_query(queriable, {key, {:not, values}}) when is_list(values) do
    queriable |> where([m], field(m, ^key) not in ^values)
  end
  defp scope_query(queriable, {key, {:like, pattern}}) do
    from m in queriable, where: like(field(m, ^key), ^"#{pattern}")
  end
  defp scope_query(queriable, {key, {:not_like, pattern}}) do
    from m in queriable, where: not like(field(m, ^key), ^"#{pattern}")
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
  defp scope_query(queriable, {key, {:json, {path, value}}})
       when is_list(path) and not is_list(value) do
    str_path = Enum.map(path, &to_str/1)
    from m in queriable, where: fragment(
      "? #>> ? = ?", field(m, ^key), ^str_path, ^map_value(value))
  end
  defp scope_query(queriable, {key, {:json, {path, value}}})
       when not is_list(path) do
    scope_query(queriable, {key, {:json, {[path], value}}})
  end
  defp scope_query(queriable, {key, {:json, {path, :>, value}}})
       when is_list(path) and is_binary(value) do
    str_path = Enum.map(path, &to_str/1)
    from m in queriable, where: fragment(
      "? #>> ? > ?", field(m, ^key), ^str_path, ^value)
  end
  defp scope_query(queriable, {key, {:json, {path, :<, value}}})
       when is_list(path) and is_binary(value) do
    str_path = Enum.map(path, &to_str/1)
    from m in queriable, where: fragment(
      "? #>> ? < ?", field(m, ^key), ^str_path, ^value)
  end
  defp scope_query(queriable, {key, {:json, {path, :>=, value}}})
       when is_list(path) and is_binary(value) do
    str_path = Enum.map(path, &to_str/1)
    from m in queriable, where: fragment(
      "? #>> ? >= ?", field(m, ^key), ^str_path, ^value)
  end
  defp scope_query(queriable, {key, {:json, {path, :<=, value}}})
       when is_list(path) and is_binary(value) do
    str_path = Enum.map(path, &to_str/1)
    from m in queriable, where: fragment(
      "? #>> ? <= ?", field(m, ^key), ^str_path, ^value)
  end
  defp scope_query(queriable, {key, {:json, {path, :like, value}}})
       when is_list(path) and is_binary(value) do
    str_path = Enum.map(path, &to_str/1)
    from m in queriable, where: fragment(
      "? #>> ? LIKE ?", field(m, ^key), ^str_path, ^value)
  end
  defp scope_query(queriable, {key, {:json, {path, :not_like, value}}})
       when is_list(path) and is_binary(value) do
    str_path = Enum.map(path, &to_str/1)
    from m in queriable, where: fragment(
      "? #>> ? NOT LIKE ?", field(m, ^key), ^str_path, ^value)
  end
  defp scope_query(queriable, {key, {:json, {path, values}}})
       when is_list(path) and is_list(values) do
    str_path = Enum.map(path, &to_str/1)
    str_values = Enum.map(values, &to_str/1)
    from m in queriable,
      where: fragment("? #>> ?", field(m, ^key), ^str_path) in ^str_values
  end
  defp scope_query(queriable, {key, {:json, {path, :not_in, values}}})
       when is_list(path) and is_list(values) do
    str_path = Enum.map(path, &to_str/1)
    str_values = Enum.map(values, &to_str/1)
    from m in queriable,
      where: fragment("? #>> ?", field(m, ^key), ^str_path) not in ^str_values
  end
  defp scope_query(queriable, {key, {:json, {path, operator, value}}}) when not is_list(path) do
    scope_query(queriable, {key, {:json, {[path], operator, value}}})
  end
  defp scope_query(queriable, {key, {:json, {path, operator, value}}}) when not is_binary(value) do
    scope_query(queriable, {key, {:json, {path, operator, map_value(value)}}})
  end

  defp to_str(key) when is_binary(key), do: key
  defp to_str(key) when is_atom(key), do: Atom.to_string(key)
  defp to_str(key), do: "#{inspect key}"

  defp map_value(true), do: "true"
  defp map_value(false), do: "false"
  defp map_value(value), do: to_str(value)
end
