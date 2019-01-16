# SimpleRepo

[![Hex Version](https://img.shields.io/hexpm/v/simple_repo.svg?style=flat-square)](https://hex.pm/packages/simple_repo) [![Docs](https://img.shields.io/badge/api-docs-orange.svg?style=flat-square)](https://hexdocs.pm/simple_repo) [![Hex downloads](https://img.shields.io/hexpm/dt/simple_repo.svg?style=flat-square)](https://hex.pm/packages/simple_repo) [![GitHub](https://img.shields.io/badge/vcs-GitHub-blue.svg?style=flat-square)](https://github.com/ertgl/simple_repo) [![MIT License](https://img.shields.io/hexpm/l/simple_repo.svg?style=flat-square)](LICENSE.txt)

This is a library enabling you to create a simple way to query for data using simple data structures like keyword lists.

## Add to dependencies

```elixir
defp deps do
  [
    {:simple_repo, "~> 1.2"}
  ]
end
```

## Usage

You can either use the SimpleRepo.Query module to create queries to use them with Ecto.Repo or add the SimpleRepo.Scoped macro to your own Repo module (see below).

```elixir
# To integrate into your Repo module you can use the Scoped macro:
defmodule MyApp.Repo do
    use Ecto.Repo, otp_app: :my_app
    use SimpleRepo.Scoped, repo: __MODULE__
end

# Create a schema and have a def changeset/2 function in place. This is a required convention to make this library work.
defmodule MyApp.User do
  use Ecto.Schema

  schema "users" do
    field :org,  :string
    field :email :string
    field :first_name, :string
    field :last_name, :integer

    timestamps()
  end

  def changeset(model, params) do
    fields = ~w(org email first_name last_name)

    model
    |> Ecto.Changeset.cast(params, fields)
    |> Ecto.Changeset.validate_required(:org)
    |> Ecto.Changeset.validate_required(:email)
    |> Ecto.Changeset.validate_required(:first_name)
    |> Ecto.Changeset.validate_required(:last_name)
  end
end

```

With this setup you can use it as follows.

```elixir
# UPDATE_SCOPED (for updates by primary key). Here "Foobar Ltd" was the former org, "Baz Ltd" is the new org.
MyApp.Repository.update_scoped(MyApp.User, 42, %{org: "Foo Ltd"}, [org: "Foobar Ltd"])
# => {:ok, %MyApp.User{id: 42, email: "foo@bar.com", first_name: "John", last_name: "Doe", org: "Baz Ltd"}}
# When invalid:
# => {:error, changeset}
# When id does not exist:
# => {:error, :not_found}

# UPDATE_ALL_SCOPED
# For update all items in a scope. The specification of the return value can be found in the Ecto.Repo documentation &update_all/3:
MyApp.Repository.update_all_scoped(MyApp.User, [set: [org: "Baz Ltd"]], [org: "Foobar Ltd"])

# BY_ID_SCOPED
# Get item by primary key ensuring a scope is satisfied
MyApp.Repository.by_id_scoped(MyApp.User, 42, [org: "Baz Ltd"])
# => {:ok, %MyApp.User{id: 42, email: "foo@bar.com", first_name: "John", last_name: "Doe", org: "Foobar Ltd"}}
# When id does not exist:
# => {:error, :not_found}

# ONE_SCOPED (to get a single element)
MyApp.Repository.one_scoped(MyApp.User, [email: "foo@bar.com])
# => {:ok, %MyApp.User{id: 42, email: "foo@bar.com", first_name: "John", last_name: "Doe", org: "Foobar Ltd"}}
# When id does not exist:
# => {:error, :not_found}
# When multiple items would match an exception is raised (See Ecto.Repo &one/2)

# ALL_SCOPED
MyApp.Repository.all_scoped(MyApp.User, [org: "Foobar Ltd"])
# => [%MyApp.User{id: 42, email: "foo@bar.com", first_name: "John", last_name: "Doe", org: "Baz Ltd"}, ...]
# .all_scoped also allows ordering via options:
MyApp.Repository.all_scoped(MyApp.User, [org: "Foobar Ltd"], [order_by: [first_name: :asc]])
# => [%MyApp.User{id: 42, email: "foo@bar.com", first_name: "Aaron", last_name: "Baron", org: "Baz Ltd"}, ...]

# DELETE_SCOPED
MyApp.Repo.delete_scoped(MyApp, 42, [org: Foobar Ldt])
# => {:ok, %MyApp.User{id: 42, email: "foo@bar.com", first_name: "John", last_name: "Doe", org: "Foobar Ltd"}}
# When no such item exists:
# => {:error, :not_found}

# DELETE_ALL_SCOPED
MyApp.Repo.delete_all_scoped(MyApp, [org: Foobar Ldt])
# => [%MyApp.User{id: 42, email: "foo@bar.com", first_name: "John", last_name: "Doe", org: "Foobar Ltd"}, ...]

# AGGREGATE_SCOPED
MyApp.Repo.aggregate_scoped(MyApp, :count, :id, [org: Foobar Ldt])
# => 3
# Also here scoping is possible
MyApp.Repository.aggregate_scoped(MyApp, :count, :id, [org: "Foobar Ltd"])
# possible aggregations: [:avg, :count, :max, :min, :sum]
```

There are different ways to add scopes. As an alternative you can also use the Query module. The opportunities are the same also syntaxwise.
Here are some examples:
```elixir
SimpleRepo.Query.scoped(MyApp.User, [last_name: "Smith"])
# Scope to all users with last_name 'Smith'

SimpleRepo.Query.scoped(MyApp.User, [last_name: {:not, "Smith"}])
# Scope to all users not having last_name 'Smith'

SimpleRepo.Query.scoped(MyApp.User, [org: nil])
# Scope to all users not belonging to an org (The library handles the NULL case for you)

SimpleRepo.Query.scoped(MyApp.User, [org: {:not, nil}])
# Scope to all users belonging to an org.

SimpleRepo.Query.scoped(MyApp.User, [first_name: ["Kevin", "Hugo", "James"]])
# Scope to all users either having 'Kevin', 'Hugo' or 'James' as first_name). This is equivalent to the SQL 'WHERE IN'

SimpleRepo.Query.scoped(MyApp.User, [first_name: {:not, ["Kevin", "Hugo", "James"]}])
# Scope to all users NOT having 'Kevin', 'Hugo' or 'James' as first_name)

SimpleRepo.Query.scoped(MyApp.User, [email: {:like, "%@gmail.%"}])
# Scope to all email addresses containing '@gmail.' Note that the '%' comes from the postgres syntax.

SimpleRepo.Query.scoped(MyApp.User, [email: {:not_like, "%@gmail.%"}])
# Scope to all email addresses NOT containing '@gmail.'

SimpleRepo.Query.scoped(MyApp.User, [inserted_at: {:<=, Ecto.DateTime.from_erl({{2017, 1, 1}, {0, 0, 0}}})])
# Scope to all users either inserted after or at 2017-01-01T00:00:00Z. Analogue you can use :<, :> and :>=.

# Again ordering is possible:
SimpleRepo.Query.ordered(MyApp.User, {:last_name, :asc})
# or
SimpleRepo.Query.ordered(MyApp.User, last_name: :asc, first_name: :asc)
# The order direction is either :asc of :desc

```

**TODOs:**
 - Bulk save made simple
 - Extend possibilities to query and scope
