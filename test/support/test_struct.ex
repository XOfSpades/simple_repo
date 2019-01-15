defmodule SimpleRepo.Support.TestStruct do
  @moduledoc """
  Only used for testing purpose.
  """
  use Ecto.Schema

  schema "test_structs" do
    field :name,      :string
    field :type,      :string
    field :value,     :integer
    field :f_value,   :float
    field :some_time, :naive_datetime

    timestamps()
  end

  def changeset(model, params \\ %{}) do
    fields = ~w(name type value f_value some_time)a

    model
    |> Ecto.Changeset.cast(params, fields)
    |> Ecto.Changeset.validate_required(:name)
    |> Ecto.Changeset.validate_required(:type)
  end
end
