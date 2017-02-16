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
        |> Enum.map(fn snake -> %{ # Transform keys to atoms and take only whats needed
            :name => snake["name"],
            :color => snake["color"],
            :head_url => snake["head_url"],
            :taunt => snake["taunt"],
            :move_url => snake["move_url"]
        } end)

        if length(queue) == 0 do
            {:error, "Not enough snakes in the game"}
        else

            # Assign each snake a random spot on the board, full health, update board, then cache snake data
            Snakes.add(for snake <- queue,
                space = Board.get_unoccupied_space,
                snake = Map.merge(snake, %{:health_points => 100}),
                Board.set_board_tile(space.x, space.y, :head, snake.name) do
                snake
            end)

            GenServer.cast(:game_server, {:init})

            :timer.apply_after(:timer.seconds(3), Web.Game, :start_game, [])

            {:ok, "New game starting in 1 minute"}
        end
    end

    def get_game_state do
        
        GenServer.call(:game_server, {:get})
    end

    def get_turn_state do

        board_state = Board.get_board()
        normalized_board = Board.get_normalized_board()
        snakes = Snakes.get_snakes()
        game = get_game_state()

        # Combines the cached snake client data with the board locations for each snake
        snake_data = Enum.map(snakes, fn snake -> %{
            taunt: snake.taunt,
            name: snake.name,
            health_points: snake.health_points,
            coords: Enum.map(Enum.filter(normalized_board, &(Map.get(&1, :snake) == snake.name)),
                fn coord -> [coord.x, coord.y] end)
        } end)

        food_data = Enum.map(Enum.filter(normalized_board, &(Map.get(&1, :state) == :food)),
                fn coord -> [coord.x, coord.y] end)

        # This is what is sent to the snakes to retrieve a move
        %{
            width: board_state.width,
            height: board_state.height,
            turn: game.turn,
            snakes: snake_data,
            board: board_state.board,
            food: food_data
        }
    end

    def start_game do
    
        perform_turn()
    end

    def perform_turn do

        get_turn_state()
        |> retrieve_moves
        |> process_moves
    end

    # Send post request to each client to retrieve the next moves based on current state
    def retrieve_moves(turn_state) do

        for snake <- Snakes.get_snakes() do
            try do
                {snake.name, HTTPoison.post(snake.move_url, elem(Poison.encode(Map.merge(turn_state, %{:you => snake.name})), 1), [{"Content-Type", "application/json"}], [recv_timeout: 200])
                |> elem(1)
                |> Map.get(:body)
                |> Poison.Parser.parse
                |> elem(1)
                |> Map.get("move")}
            rescue
                _ -> {snake.name, elem({"up", "down", "left", "right"}, :rand.uniform(3))}
            end
        end
    end

    def process_moves(moves) do

        initial_board = Board.get_board()
        normalized_board = Board.get_normalized_board()

        new_moves = for move <- moves,
            name = elem(move, 0),
            direction = elem(move, 1),
            position = Enum.find(normalized_board, fn cell -> cell[:snake] == name && cell[:state] == :head end),
            dest_coord = get_new_position_from_move(position.x, position.y, direction),
            dest_tile = Board.get_board_tile(dest_coord[:x], dest_coord[:y]) do
                cond do
                    dest_tile == nil -> "dead"
                    dest_tile.state == :empty -> {name, position, direction, dest_coord}
                end
        end

        for move <- new_moves,
            position = elem(move, 1),
            dest = elem(move, 3),
            name = elem(move, 0) do
            cond do
                move == "dead" -> Board.set_board_tile(move.position.x, move.position.y, :empty, nil)
                true -> move_snake(name, position.x, position.y, dest[:x], dest[:y])
            end
        end
    end

    def move_snake(name, x, y, new_x, new_y) do

        Board.set_board_tile(x, y, :empty, nil)
        Board.set_board_tile(new_x, new_y, :head, name)
    end

    def get_new_position_from_move(x, y, direction) do
        
        cond do
            direction == "up" -> [x: x, y: y-1]
            direction == "down" -> [x: x, y: y+1]
            direction == "left" -> [x: x+1, y: y]
            direction == "right" -> [x: x-1, y: y]
        end
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