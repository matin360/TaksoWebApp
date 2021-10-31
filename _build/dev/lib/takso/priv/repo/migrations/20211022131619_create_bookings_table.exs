defmodule Takso.Repo.Migrations.CreateBookingsTable do
  use Ecto.Migration

  def change do
    create table(:bookings) do
      add :pickup_address, :string
      add :dropoff_address, :string
      add :status, :string, default: "open"
      add :user_id, references(:users)
      timestamps()
    end
  end
end
