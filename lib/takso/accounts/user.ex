defmodule Takso.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :name, :string
    field :email, :string
    field :password, :string
    field :age, :integer
    field :is_customer, :boolean
    has_many :bookings, Takso.Sales.Booking
    has_one :taxis, Takso.Sales.Taxi

    timestamps()
  end

  @doc false
  def changeset(user, params \\ %{}) do
    user
    |> cast(params, [:name, :email, :password, :age, :is_customer])
    |> validate_required([:name, :email, :password, :age, :is_customer])
    |> validate_format(:email, ~r/@/)
    |> validate_inclusion(:age, 18..100)
    |> unique_constraint(:email)
  end
end
