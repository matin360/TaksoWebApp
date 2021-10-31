defmodule Takso.Repo.Migrations.AddNewColumnsToTaxis do
  use Ecto.Migration

  def change do
    alter table(:taxis) do
      add :completed_rides_num, :integer
      add :cost_per_km, :float
    end
  end
end
