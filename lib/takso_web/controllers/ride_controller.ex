defmodule TaksoWeb.RideController do
  use TaksoWeb, :controller

  alias Ecto.{Changeset, Multi}
  alias Takso.{Repo, Sales.Taxi, Sales.Booking, Sales.Allocation, Accounts.User}
  import Ecto.Query, only: [from: 2]

  def index(conn, _params) do
    user_id = conn.assigns.current_user.id

    query = from b in Booking,
            join: a in Allocation,
            join: t in Taxi,
            join: u in User,
            on: b.id == a.booking_id and
              t.id == a.taxi_id and
              u.id == t.user_id,
            where: u.id == ^user_id,
            select: %BookingDetails{
              id: b.id,
              pickup_address: b.pickup_address,
              dropoff_address: b.dropoff_address,
              status: a.status,
              driver_fullname: u.name,
              cost_per_km: t.cost_per_km,
              completed_rides_num: t.completed_rides_num}

    assigned_rides = Repo.all(query)
    render conn, "index.html", details: assigned_rides
  end

  def show(conn, %{"id" => booking_id}) do
    user = conn.assigns.current_user

    query = from b in Booking, where: b.id == ^booking_id, select: b
    booking = Takso.Repo.one(query)
    changeset = booking && Booking.changeset(booking, %{})

    query = from b in Booking,
            join: a in Allocation,
            join: t in Taxi,
            join: u in User,
            on: b.id == a.booking_id and
              t.id == a.taxi_id and
              u.id == t.user_id,
            where: u.id == ^user.id and b.id == ^booking_id,
            select: %BookingDetails{
              id: b.id,
              pickup_address: b.pickup_address,
              dropoff_address: b.dropoff_address,
              status: a.status,
              driver_fullname: u.name,
              cost_per_km: t.cost_per_km,
              completed_rides_num: t.completed_rides_num}

    current_ride = Repo.one(query)
    IO.inspect(current_ride)

    if (current_ride) do
      render(conn, "show.html", booking: current_ride, changeset: changeset)
    else
      conn
      |> put_flash(:error, "Ride not found")
      |> redirect(to: Routes.ride_path(conn, :index))
    end
 end

 def complete_ride(conn, %{"id" => booking_id}) do
  user = conn.assigns.current_user

  booking = Takso.Repo.one(from b in Booking, where: b.id == ^booking_id, select: b)
  booking_with_taxi = booking && booking
  |> Repo.preload(:taxis)

  taxi = booking_with_taxi && booking_with_taxi.taxis |> List.first

  if (taxi && taxi.user_id != user.id) do
    conn
    |> put_flash(:error, "You are not authorized to perform this action.")
    |> redirect(to: Routes.ride_path(conn, :index))
  end

  allocation = taxi && Takso.Repo.one(
    from a in Allocation,
    where: a.booking_id == ^booking_id and
    a.taxi_id == ^taxi.id,
    select: a)

  if (allocation) do
    Multi.new
    |> Multi.update(:allocation, Allocation.changeset(allocation, %{status: "completed"}))
    |> Multi.update(:taxi, Taxi.changeset(taxi, %{})
        |> Changeset.put_change(:status, "available")
        |> Changeset.put_change(:completed_rides_num, taxi.completed_rides_num + 1))
    |> Repo.transaction

    redirect(conn, to: Routes.ride_path(conn, :index))
  else
    conn
    |> put_flash(:error, "Something went wrong")
    |> redirect(to: Routes.ride_path(conn, :index))
  end
  end
end
