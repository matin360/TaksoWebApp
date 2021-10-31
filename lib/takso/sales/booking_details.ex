defmodule BookingDetails do
  defstruct [
    :id,
    :pickup_address,
    :dropoff_address,
    :distance,
    :status,
    :driver_fullname,
    :cost_per_km,
    :completed_rides_num]
end
