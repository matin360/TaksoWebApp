defmodule Takso.Repo.Migrations.AddCapacityAndUserToTaxis do
  use Ecto.Migration

  def change do
    alter table(:taxis) do
      remove :username, :string
      add :capacity, :integer
      add :user_id, references(:users)
    end
  end
end
