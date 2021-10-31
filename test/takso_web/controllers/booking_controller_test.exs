defmodule TaksoWeb.BookingControllerTest do
  use TaksoWeb.ConnCase

  alias Takso.{Sales.Taxi, Repo, Accounts.User}

  setup do
    user =
      %User{
        name: "Matin",
        email: "matin@ut.ee",
        password: "12",
        age: 22,
        is_customer: true,
        id: 1
      }
      |> Repo.insert!()

    conn =
      build_conn()
      |> Plug.Test.init_test_session(current_user: user, user_id: to_string(user.id))

    {:ok, conn: conn}
  end

  test "Booking Acceptance", %{conn: conn} do
    Repo.insert!(%User{is_customer: false, email: "adil@ut.ee", id: 2, name: "Adil"})
    Repo.insert!(%Taxi{status: "available", user_id: 2, cost_per_km: 0.5, capacity: 4, location: "Narva 25", completed_rides_num: 0, id: 1})
    conn =
      post(conn, "bookings", %{
        pickup_address: "Liivi 2",
        dropoff_address: "Muuseumi tee 2",
        distance: "2.0"
      })

    conn = get(conn, redirected_to(conn))

    driver = Repo.get(User, 2)
    taxi = Repo.get(Taxi, 1)
    assert html_response(conn, 200) =~
    "Taxi driver #{driver.name} with #{taxi.capacity} seats is #{2.0} km away in #{taxi.location}. Price: #{Float.round(2.0 * taxi.cost_per_km, 2)}. "
  end

  test "Booking Acceptance with lowest price", %{conn: conn} do
    Repo.insert!(%User{is_customer: false, email: "adil@ut.ee", id: 2, name: "Adil"})
    Repo.insert!(%User{is_customer: false, email: "kamil@ut.ee", id: 3, name: "Kamil"})
    Repo.insert!(%Taxi{status: "available", user_id: 2, cost_per_km: 0.5, capacity: 4, location: "Narva 25", completed_rides_num: 0, id: 1})
    Repo.insert!(%Taxi{status: "available", user_id: 3, cost_per_km: 0.3, capacity: 4, location: "Narva 25", completed_rides_num: 0, id: 2})
    conn =
      post(conn, "bookings", %{
        pickup_address: "Liivi 2",
        dropoff_address: "Muuseumi tee 2",
        distance: "2.0"
      })

    conn = get(conn, redirected_to(conn))

    driver = Repo.get(User, 3)
    taxi = Repo.get(Taxi, 2)
    assert html_response(conn, 200) =~
    "Taxi driver #{driver.name} with #{taxi.capacity} seats is #{2.0} km away in #{taxi.location}. Price: #{Float.round(2.0 * taxi.cost_per_km, 2)}. "
  end

  test "Booking Acceptance with lowest number of completed rides", %{conn: conn} do
    Repo.insert!(%User{is_customer: false, email: "adil@ut.ee", id: 2, name: "Adil"})
    Repo.insert!(%User{is_customer: false, email: "kamil@ut.ee", id: 3, name: "Kamil"})
    Repo.insert!(%Taxi{status: "available", user_id: 2, cost_per_km: 0.5, capacity: 4, location: "Narva 25", completed_rides_num: 1, id: 1})
    Repo.insert!(%Taxi{status: "available", user_id: 3, cost_per_km: 0.5, capacity: 4, location: "Narva 25", completed_rides_num: 0, id: 2})
    conn =
      post(conn, "bookings", %{
        pickup_address: "Liivi 2",
        dropoff_address: "Muuseumi tee 2",
        distance: "2.0"
      })

    conn = get(conn, redirected_to(conn))

    driver = Repo.get(User, 3)
    taxi = Repo.get(Taxi, 2)
    assert html_response(conn, 200) =~
    "Taxi driver #{driver.name} with #{taxi.capacity} seats is #{2.0} km away in #{taxi.location}. Price: #{Float.round(2.0 * taxi.cost_per_km, 2)}. "
  end

  test "Booking Rejection", %{conn: conn} do
    Repo.insert!(%Taxi{status: "busy"})

    conn =
      post(conn, "bookings", %{
        pickup_address: "Liivi 2",
        dropoff_address: "Muuseumi tee 2",
        distance: "2.0"
      })

    conn = get(conn, redirected_to(conn))
    assert html_response(conn, 200) =~ ~r/At present, there is no taxi available!/
  end

  test "Booking requires a 'pickup address'", %{conn: conn} do

    conn =
      post(conn, "bookings", %{
        pickup_address: "",
        dropoff_address: "Muuseumi tee 2",
        distance: "2.0"
      })

    assert html_response(conn, 200) =~ "Pickup address cannot be empty"
  end

  test "Booking requires a 'dropoff address'", %{conn: conn} do

    conn =
      post(conn, "bookings", %{
        pickup_address: "Narva",
        dropoff_address: "",
        distance: "2.0"
      })

    assert html_response(conn, 200) =~ "Dropoff address cannot be empty"
  end

  test "Booking requires a 'distance'", %{conn: conn} do

    conn =
      post(conn, "bookings", %{
        pickup_address: "Narva 25",
        dropoff_address: "Muuseumi tee 2",
        distance: ""
      })

    assert html_response(conn, 200) =~ "Distance cannot be empty"
  end

  test "Booking requires a 'distance' to be positive", %{conn: conn} do

    conn =
      post(conn, "bookings", %{
        pickup_address: "Narva 25",
        dropoff_address: "Muuseumi tee 2",
        distance: "-3"
      })

    assert html_response(conn, 200) =~ "Distance cannot be less than zero"
  end

  test "Booking requires 'dropoff address' and 'pickup address' to be diffrent", %{conn: conn} do

    conn =
      post(conn, "bookings", %{
        pickup_address: "Narva 25",
        dropoff_address: "Narva 25",
        distance: "3"
      })

    assert html_response(conn, 200) =~ "Dropoff address and Pickup address have to be diffrent"
  end
end
