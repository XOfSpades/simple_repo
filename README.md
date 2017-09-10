# SimpleRepo

[![Hex Version](https://img.shields.io/hexpm/v/simple_repo.svg?style=flat-square)](https://hex.pm/packages/simple_repo) [![Docs](https://img.shields.io/badge/api-docs-orange.svg?style=flat-square)](https://hexdocs.pm/simple_repo) [![Hex downloads](https://img.shields.io/hexpm/dt/simple_repo.svg?style=flat-square)](https://hex.pm/packages/simple_repo) [![GitHub](https://img.shields.io/badge/vcs-GitHub-blue.svg?style=flat-square)](https://github.com/ertgl/simple_repo) [![MIT License](https://img.shields.io/hexpm/l/simple_repo.svg?style=flat-square)](LICENSE.txt)

This is a library enabling you to create a simple way to query for data using simple data structures like keyword lists.

## Usage

This library is designed as a macro. You can add it's functionality to any module not conflicting the interface. But I recomment using it in an own empty module.

```elixir
defmodule MyApp.Repo do
    use Ecto.Repo, otp_app: :my_app
end

defmodule MyApp.Repository do
    use SimpleRepo.Repository, repo: MyApp.Repo
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
# SAVE
MyApp.Repository.save((%MyApp.User{}, %{email: "foo@bar.com", first_name: "John", last_name: "Doe", org: "Foobar Ltd"}))
# => {:ok, %MyApp.User{id: 42, email: "foo@bar.com", first_name: "John", last_name: "Doe", org: "Foobar Ltd"}}
# When invalid:
# => {:error, changeset}

# REVISE (for updates)
MyApp.Repository.patch(MyApp.User, 42, %{org: "Baz Ltd"})
# => {:ok, %MyApp.User{id: 42, email: "foo@bar.com", first_name: "John", last_name: "Doe", org: "Baz Ltd"}}
# When invalid:
# => {:error, changeset}
# When id does not exist:
# => {:error, :not_found}

# For update scoping to a specified search space is possible:
MyApp.Repository.patch(MyApp.User, 42, %{org: "Baz Ltd"}, [org: "Foobar Ltd"])
# Returns {:error, :not found} if no user with id = 42 and org = "Foobar Ltd"} exists

# ONE (to get a single element)
MyApp.Repository.one(MyApp.User, 42)
# => {:ok, %MyApp.User{id: 42, email: "foo@bar.com", first_name: "John", last_name: "Doe", org: "Foobar Ltd"}}
# When id does not exist:
# => {:error, :not_found}

# For get scoping to a specified search space is possible:
MyApp.Repository.one(MyApp.User, 42, [org: "Foobar Ltd"])
# Returns {:error, :not found} if no user with id = 42 and org = "Foobar Ltd"} exists

# ALL
MyApp.Repository.all(MyApp.User)
# => [%MyApp.User{id: 42, email: "foo@bar.com", first_name: "John", last_name: "Doe", org: "Baz Ltd"}, ...]
# Again scoping to a specified search space is possible:
MyApp.Repository.all(MyApp.User, [org: "Foobar Ltd"])

# DESTROY
MyApp.Repository.destroy(MyApp, 42)
# => {:ok, %MyApp.User{id: 42, email: "foo@bar.com", first_name: "John", last_name: "Doe", org: "Foobar Ltd"}}
# When no such item exists:
# => {:error, :not_found}

# Again scoping to a smaller search space is possible:
MyApp.Repository.destroy(MyApp, 42, [org: "Foobar Ltd"])

# AGGREGATE
MyApp.Repository.aggregate(MyApp, :count, :id)
# => 1
# Also here scoping is possible
MyApp.Repository.aggregate(MyApp, :count, :id, [org: "Foobar Ltd"])
# possible aggregations: [:avg, :count, :max, :min, :sum]
```

There are different ways to add scopes/queries. Here are some examples:
```elixir
MyApp.Repository.all(MyApp.User, [:last_name, "Smith"])
# Query for all users with last_name 'Smith'

MyApp.Repository.all(MyApp.User, [:last_name, {:not, "Smith"}])
# Query for all users not having last_name 'Smith'

MyApp.Repository.all(MyApp.User, [:org, nil])
# Query for all users not belonging to an org (The library handles the NULL case for you)

MyApp.Repository.all(MyApp.User, [:org, {:not, nil}])
# Query for all users belonging to an org.

MyApp.Repository.all(MyApp.User, [:first_name, ["Kevin", "Hugo", "James"]])
# Query for all users either having 'Kevin', 'Hugo' or 'James' as first_name). This is equivalent to the SQL 'WHERE IN'

MyApp.Repository.all(MyApp.User, [:first_name, {:not, ["Kevin", "Hugo", "James"]}])
# Query for all users NOT having 'Kevin', 'Hugo' or 'James' as first_name)

MyApp.Repository.all(MyApp.User, [:email, {:like, "@gmail."}])
# Scope to all email addresses containing '@gmail.'

MyApp.Repository.all(MyApp.User, [:email, {:not_like, "@gmail."}])
# Scope to all email addresses NOT containing '@gmail.'

```

**TODOs:**
 - Bulk save made simple
 - Extend possibilities to query and scope
