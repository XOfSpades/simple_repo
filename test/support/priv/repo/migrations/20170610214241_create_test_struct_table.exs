defmodule SimpleRepo.Support.Repo.Migrations.CreateTestStructTable do
  use Ecto.Migration

  def change do
    create table(:test_structs) do
      add :uuid,      :binary_id, null: false
      add :name,      :string, size: 30, null: false
      add :type,      :string, size: 10, null: false
      add :value,     :integer
      add :f_value,   :float
      add :some_time, :naive_datetime
      add :jsonb,     :map

      timestamps()
    end
  end
end
