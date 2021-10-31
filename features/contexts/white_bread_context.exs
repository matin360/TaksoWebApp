defmodule WhiteBreadContext do
  use WhiteBread.Context
  use Hound.Helpers

  import Ecto.Query, only: [from: 2]

  alias Takso.{Repo, Sales.Taxi, Accounts.User}

  feature_starting_state(fn ->
    Application.ensure_all_started(:hound)
    %{}
  end)

  scenario_starting_state(fn state ->
    Hound.start_session()
    Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
    %{}
  end)

  scenario_finalize(fn _status, _state ->
    Ecto.Adapters.SQL.Sandbox.checkin(Repo)
    # Hound.end_session
    Nil
  end)

  given_(~r/^the following taxis are on duty$/, fn state, %{table_data: table} ->
    table
    |> Enum.map(fn taxi_data ->
      query = from(u in User, where: u.email == ^taxi_data.email, select: u)
      user = Takso.Repo.one(query)
      taxi_fields = Map.take(taxi_data, [:status, :location, :capacity, :cost_per_km])

      taxi_struct =
        Ecto.build_assoc(user, :taxis)
        |> Ecto.Changeset.cast(taxi_fields, [:capacity, :cost_per_km, :status, :location])

      Taxi.changeset(taxi_struct, %{})
    end)
    |> Enum.each(fn changeset -> Repo.insert!(changeset) end)
  end)

  and_(~r/^the following users$/, fn state, %{table_data: users} ->
    users
    |> Enum.map(fn user -> User.changeset(%User{}, user) end)
    |> Enum.each(fn changeset -> Repo.insert!(changeset) end)

    {:ok, state}
  end)

  # steps are mixed together as we don't want to concentrate here
  # it's added just to bypass the authentication part and access page
  and_(
    ~r/^I login to the system as "(?<email>[^"]+)" with password "(?<password>[^"]+)"$/,
    fn state, %{email: email, password: password} ->
      navigate_to("/sessions/new")
      fill_field({:id, "session_email"}, email)
      fill_field({:id, "session_password"}, password)
      click({:id, "submit_button"})
      {:ok, state}
    end
  )

  and_(~r/^I open STRS' web page$/, fn state ->
    navigate_to("/bookings/new")
    {:ok, state}
  end)

  and_(
    ~r/^I enter the booking information$/,
    fn state ->
      fill_field({:id, "pickup_address"}, state[:pickup_address])
      fill_field({:id, "dropoff_address"}, state[:dropoff_address])
      fill_field({:id, "distance"}, state[:distance])
      {:ok, state}
    end
  )

  and_(
    ~r/^I want to go from "(?<pickup_address>[^"]+)" to "(?<dropoff_address>[^"]+)" with distance "(?<distance>[^"]+)"$/,
    fn state,
       %{pickup_address: pickup_address, dropoff_address: dropoff_address, distance: distance} ->
      {:ok,
       state
       |> Map.put(:pickup_address, pickup_address)
       |> Map.put(:dropoff_address, dropoff_address)
       |> Map.put(:distance, distance)}
    end
  )

  when_(~r/^I submit the booking request$/, fn state ->
    click({:id, "submit_button"})
    {:ok, state}
  end)

  then_(~r/^I should receive a confirmation message$/, fn state ->
    assert visible_in_page?(
             ~r/Taxi driver .+ with .+ seats is \d.\d km away in .+ Price: \d.\d./
           )

    {:ok, state}
  end)

  then_(~r/^I should receive a rejection message$/, fn state ->
    assert visible_in_page?(~r/At present, there is no taxi available!/)
    {:ok, state}
  end)
end
