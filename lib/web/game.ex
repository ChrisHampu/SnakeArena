defmodule Web.Game do
    use GenServer
    alias Web.Queue
    alias Web.Board
    alias Web.Snakes

    def start_link(state, opts \\ []) do
        GenServer.start_link(__MODULE__, state, opts)
    end

    def try_new_game do

        state = GenServer.call(:game_server, {:get})
        
        IO.inspect state

        if state[:state] == :finished do
            new_game()
        end
    end

    # Initiates game logic using current queue
    def new_game do

        Board.init_board() 
        board = Board.get_board()

        state = elem(Poison.encode(%{:width => board[:width], :height => board[:height]}), 1)

        queue = Queue.pull_all()
        |> Enum.map(&elem(&1, 0))
        |> Enum.map(fn url -> HTTPoison.post("#{url}/start", state, [{"Content-Type", "application/json"}], [recv_timeout: 200]) end) # Send post request
        |> Enum.filter(fn status -> elem(status, 0) == :ok end) # Ensure request succeeded
        |> Enum.map(&Map.get(elem(&1, 1), :body)) # Get request body
        |> Enum.map(&Poison.Parser.parse(&1)) # Parse json
        |> Enum.filter_map(&(elem(&1, 0) == :ok), &(elem(&1, 1))) # Ensure parser succeeded

        if length(queue) == 0 do
            {:error, "Not enough snakes in the game"}
        else

            Snakes.add(queue)

            GenServer.cast(:game_server, {:init})

            :timer.apply_after(:timer.seconds(3), Web.Game, :start_game, [])

            {:ok, "New game starting in 1 minute"}
        end
    end

    def get_game_state do
        
        GenServer.call(:game_server, {:get})
    end

    def start_game do
    
        IO.puts "start"
    end

    def retrieve_moves do

        IO.puts "moves"
    end

    def end_game do

        GenServer.call(:game_server, {:end})
    end
    
    # Server API

    def handle_call({:get}, _from, state) do

        {:reply, state, state}
    end

    def handle_call({:end}, _from, state) do

        {:reply, state, %{:state => :finished}}
    end

    def handle_cast({:init}, _state) do

        {:noreply, %{:turn => 0, :state => :started}}
    end
end