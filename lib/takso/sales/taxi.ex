defmodule Takso.Sales.Taxi do
  use Ecto.Schema
  import Ecto.Changeset

  schema "taxis" do
    field :location, :string
    field :status, :string
    field :completed_rides_num, :integer, default: 0
    field :cost_per_km, :float
    field :capacity, :integer
    belongs_to :user, Takso.Accounts.User
    many_to_many :bookings, Takso.Sales.Booking, join_through: "allocations"

    timestamps()
  end

  @doc false
  def changeset(taxi, attrs) do
    taxi
    |> cast(attrs, [:location, :status, :completed_rides_num, :cost_per_km, :capacity])
    |> validate_required([:cost_per_km, :capacity])
    |> validate_number(:cost_per_km, [greater_than: 0])
  end
end
