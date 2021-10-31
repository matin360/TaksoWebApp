defmodule TaksoWeb.BookingController do
  use TaksoWeb, :controller

  alias Takso.{Repo, Sales.Taxi, Sales.Booking, Sales.Allocation, Accounts.User}
  alias Ecto.{Changeset, Multi}

  import Ecto.Query, only: [from: 2]

  def index(conn, _params) do
    bookings = Repo.all(from b in Booking, where: b.user_id == ^conn.assigns.current_user.id)
    render conn, "index.html", bookings: bookings
  end

  def new(conn, _params) do
    render conn, "new.html"
  end

  def show(conn, %{"id" => id}) do
    query = from b in Booking, where: b.id == ^id, select: b
    booking = Repo.one(query)

    if (booking && booking.status == "rejected") do
      render(conn, "show.html", bookingDetails: %BookingDetails{
        pickup_address: booking.pickup_address,
        dropoff_address: booking.dropoff_address,
        status: booking.status,
        driver_fullname: "N/A",
        cost_per_km: "N/A",
        completed_rides_num: "N/A"})
    else
      query = from b in Booking,
      join: a in Allocation,
      join: t in Taxi,
      join: u in User,
      on: b.id == a.booking_id and
        t.id == a.taxi_id and
        u.id == t.user_id,
      where: b.id == ^id,
      select: %BookingDetails{
        pickup_address: b.pickup_address,
        dropoff_address: b.dropoff_address,
        status: b.status,
        driver_fullname: u.name,
        cost_per_km: t.cost_per_km,
        completed_rides_num: t.completed_rides_num}

      render(conn, "show.html", bookingDetails: Repo.one(query))
    end
  end

  def create(conn, booking_params) do
    cond do
    booking_params["pickup_address"] === nil ||  booking_params["pickup_address"] === "" -> conn
                                                  |> put_flash(:error, "Pickup address cannot be empty")
                                                  |> render("new.html")
    booking_params["dropoff_address"] === nil ||  booking_params["dropoff_address"] === "" -> conn
                                                  |> put_flash(:error, "Dropoff address cannot be empty")
                                                  |> render("new.html")
    booking_params["dropoff_address"] === booking_params["pickup_address"] -> conn
                                                  |> put_flash(:error, "Dropoff address and Pickup address have to be diffrent")
                                                  |> render("new.html")
    booking_params["distance"] === nil ||  booking_params["distance"] === "" -> conn
                                                  |> put_flash(:error, "Distance cannot be empty")
                                                  |> render("new.html")
    List.first(Tuple.to_list(Float.parse(booking_params["distance"]))) <= 0 -> conn
                                                  |> put_flash(:error, "Distance cannot be less than zero")
                                                  |> render("new.html")
    true ->     user = conn.assigns.current_user
            # convert distance into float
            {parsedDistance, _} = Float.parse(booking_params["distance"])

            booking_struct = Ecto.build_assoc(user, :bookings, Enum.map(booking_params, fn({key, value}) -> {String.to_atom(key), value} end))
            changeset = Booking.changeset(booking_struct, %{})
                        |> Changeset.put_change(:status, "open")
                        |> Changeset.put_change(:distance, parsedDistance)

            booking = Repo.insert!(changeset)

            query = from t in Taxi, where: t.status == "available", select: t
            available_taxis = Takso.Repo.all(query)
            case length(available_taxis) do
              1 -> taxi = List.first(available_taxis)
                      Multi.new
                      |> Multi.insert(:allocation, Allocation.changeset(%Allocation{}, %{status: "accepted"}) |> Changeset.put_change(:booking_id, booking.id) |> Changeset.put_change(:taxi_id, taxi.id))
                      |> Multi.update(:taxi, Taxi.changeset(taxi, %{}) |> Changeset.put_change(:status, "busy"))
                      |> Multi.update(:booking, Booking.changeset(booking, %{}) |> Changeset.put_change(:status, "allocated"))
                      |> Repo.transaction

                      # get driver's data
                      driver = Takso.Repo.get_by(User, id: taxi.user_id)

                      conn
                      |> put_flash(:info, "Taxi driver #{driver.name} with #{taxi.capacity} seats is #{parsedDistance} km away in #{taxi.location}. Price: #{Float.round(parsedDistance * taxi.cost_per_km, 2)}. ")
                      |> redirect(to: Routes.booking_path(conn, :new))

              0    -> Booking.changeset(booking) |> Changeset.put_change(:status, "rejected")
                      |> Repo.update
                      conn
                      |> put_flash(:info, "At present, there is no taxi available!")
                      |> redirect(to: Routes.booking_path(conn, :new))

              _    -> taxi = Enum.min_by(available_taxis, &(&1.cost_per_km))
                      taxis_with_same_prices = Enum.filter(available_taxis, fn t -> t.cost_per_km == taxi.cost_per_km end)
                      case length(taxis_with_same_prices) do
                         1 ->
                          Multi.new
                          |> Multi.insert(:allocation, Allocation.changeset(%Allocation{}, %{status: "accepted"}) |> Changeset.put_change(:booking_id, booking.id) |> Changeset.put_change(:taxi_id, taxi.id))
                          |> Multi.update(:taxi, Taxi.changeset(taxi, %{}) |> Changeset.put_change(:status, "busy"))
                          |> Multi.update(:booking, Booking.changeset(booking, %{}) |> Changeset.put_change(:status, "allocated"))
                          |> Repo.transaction

                          # get driver's data
                          driver = Takso.Repo.get_by(User, id: taxi.user_id)

                          conn
                          |> put_flash(:info, "Taxi driver #{driver.name} with #{taxi.capacity} seats is #{parsedDistance} km away in #{taxi.location}. Price: #{Float.round(parsedDistance * taxi.cost_per_km, 2)}. ")
                          |> redirect(to: Routes.booking_path(conn, :new))
                          _ ->
                            taxi_with_least_comp_rides = Enum.min_by(taxis_with_same_prices, &(&1.completed_rides_num))
                            Multi.new
                            |> Multi.insert(:allocation, Allocation.changeset(%Allocation{}, %{status: "accepted"}) |> Changeset.put_change(:booking_id, booking.id) |> Changeset.put_change(:taxi_id, taxi_with_least_comp_rides.id))
                            |> Multi.update(:taxi, Taxi.changeset(taxi_with_least_comp_rides, %{}) |> Changeset.put_change(:status, "busy"))
                            |> Multi.update(:booking, Booking.changeset(booking, %{}) |> Changeset.put_change(:status, "allocated"))
                            |> Repo.transaction

                            # get driver's data
                            driver = Takso.Repo.get_by(User, id: taxi_with_least_comp_rides.user_id)

                            conn
                            |> put_flash(:info, "Taxi driver #{driver.name} with #{taxi_with_least_comp_rides.capacity} seats is #{parsedDistance} km away in #{taxi_with_least_comp_rides.location}. Price: #{Float.round(parsedDistance * taxi_with_least_comp_rides.cost_per_km, 2)}. ")
                            |> redirect(to: Routes.booking_path(conn, :new))
                      end

            end
    end

  end

  def summary(conn, _params) do
    query = from t in Taxi,
            join: a in Allocation, on: t.id == a.taxi_id,
            join: u in User, on: t.user_id == u.id,
            group_by: u.email,
            where: a.status == "accepted",
            select: {u.email, count(a.id)}
    render conn, "summary.html", tuples: Repo.all(query)
  end

end
