defmodule BinaryClock.Server do
  use GenServer
  @spi_bus_name "spidev0.0"
  @timezone "US/Eastern"
  
  alias BinaryClock.Core

  def start_link(initial_state \\ "US/Eastern") do
    GenServer.start_link(__MODULE__, initial_state, name: __MODULE__)
  end
  
  def tick do
    send(__MODULE__, :tick)
  end
  
  def init(timezone) do
    IO.puts("initializing with #{timezone}")
    {:ok, spi} = Circuits.SPI.open(@spi_bus_name)
    :timer.send_interval(1_000, :tick)

    {:ok, %{timezone: timezone, spi: spi}}
  end
  
  def handle_info(:tick, clock) do
    IO.puts("Processing tick")
    light_leds(clock)
    {:noreply, clock}
  end
  
  def light_leds(%{spi: spi, timezone: timezone}) do      
    Circuits.SPI.transfer(spi, time_in_bytes(timezone))
  end
  
  def time_in_bytes(timezone) do
    timezone
    |> DateTime.now!(Tzdata.TimeZoneDatabase)
    |> Core.new
    |> Core.to_leds
  end
end