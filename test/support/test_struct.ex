defmodule SimpleRepo.Support.TestStruct do
  @moduledoc """
  Only used for testing purpose.
  """
  use Ecto.Schema

  schema "test_structs" do
    field :name,    :string
    field :type,    :string
    field :value,   :integer
    field :f_value, :float

    timestamps()
  end

  def changeset(model, params \\ :empty) do
    fields = ~w(name type value f_value)

    model
    |> Ecto.Changeset.cast(params, fields)
    |> Ecto.Changeset.validate_required(:name)
    |> Ecto.Changeset.validate_required(:type)
  end
end
