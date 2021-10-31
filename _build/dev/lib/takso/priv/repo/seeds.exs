# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Takso.Repo.insert!(%Takso.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

import Ecto.Query, only: [from: 2]
alias Takso.{Repo, Accounts.User, Sales.Taxi, Sales.Allocation, Sales.Booking}
alias Ecto.Changeset

users = [%{name: "Fred Flintstone", email: "fred@ut.ee", password: "parool", age: 20, is_customer: true},
 %{name: "Barney Rubble", email: "barney@ut.ee", password: "parool", age: 34, is_customer: true},
 %{name: "Thomas", email: "thomas@ut.ee", password: "parool", age: 34, is_customer: false},
 %{name: "Jonas", email: "jonas@ut.ee", password: "parool", age: 26, is_customer: false}]

users
|> Enum.map(fn user_data -> User.changeset(%User{}, user_data) end)
|> Enum.each(fn changeset -> Repo.insert!(changeset) end)


taxis = [%{location: "Narva 25", status: "available", capacity: 4, cost_per_km: 2.3, user_email: "thomas@ut.ee"},
 %{location: "Liivi 2", status: "busy", capacity: 4, cost_per_km: 2.3, user_email: "jonas@ut.ee"}]

taxis
|> Enum.map(fn taxi_data ->
    query = from u in User, where: u.email == ^taxi_data.user_email, select: u
    user = Takso.Repo.one(query)
    taxi_fields = Map.take(taxi_data, [:status, :location, :capacity, :cost_per_km])
    taxi_struct = Ecto.build_assoc(user, :taxis, Enum.map(taxi_fields, fn({key, value}) -> {key, value} end))
    Taxi.changeset(taxi_struct, %{})
  end)
|> Enum.each(fn changeset -> Repo.insert!(changeset) end)

bookings = [%{pickup_address: "Narva 25", dropoff_address: "Raatuse 22", status: "accepted", distance: 2.0, user_email: "fred@ut.ee"},
%{pickup_address: "Jakobi 25", dropoff_address: "Raatuse 4", status: "rejected", distance: 4.0, user_email: "fred@ut.ee"}]

bookings
|> Enum.map(fn booking_data ->
    query = from u in User, where: u.email == ^booking_data.user_email, select: u
    user = Takso.Repo.one(query)
    booking_fields = Map.take(booking_data, [:pickup_address, :dropoff_address, :status, :distance])
    booking_struct = Ecto.build_assoc(user, :bookings, Enum.map(booking_fields, fn({key, value}) -> {key, value} end))
    Booking.changeset(booking_struct, %{})
  end)
|> Enum.each(fn changeset -> Repo.insert!(changeset) end)

allocation = Allocation.changeset(%Allocation{},
  %{status: "accepted"}) |> Changeset.put_change(:booking_id, 1) |> Changeset.put_change(:taxi_id, 2)
Repo.insert(allocation)
