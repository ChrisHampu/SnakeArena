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

        GenServer.cast(:game_server, {:init})

        Web.SnakeChannel.broadcast_state()

        :timer.apply_after(:timer.seconds(5), Web.Game, :start_game, [])

        {:ok, "New game starting in 1 minute"}
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

        Board.init_board() 
        board = Board.get_board()

        state = elem(Poison.encode(%{:width => board[:width], :height => board[:height], :game_id => 'placeholder'}), 1)

        queue = Queue.pull_all()
        |> Enum.map(&elem(&1, 0))
        |> Enum.map(fn url -> 
            request = HTTPoison.post("#{url}/start", state, [{"Content-Type", "application/json"}], [recv_timeout: 200])

            cond do
                elem(request, 0) == :ok ->
                    snake = Map.get(elem(request, 1), :body)
                    |> Poison.Parser.parse()
                    |> elem(1)
                    
                    {:ok, %{ # Transform keys to atoms and take only whats needed
                        :name => snake["name"],
                        :color => snake["color"],
                        :head_url => snake["head_url"],
                        :taunt => snake["taunt"],
                        :move_url => "#{url}/move",
                        :health_points => 100,
                        :coords => [Map.values(Map.take(Board.get_unoccupied_space(), [:x, :y]))]
                    }}
                true -> {:error, %{}}
            end
        end)
        |> Enum.filter_map(&elem(&1, 0) == :ok, &elem(&1, 1))

       if length(queue) == 0 do

            end_game()

            {:error, "Not enough snakes in the game"}
        else

            Snakes.add(queue)

            GenServer.cast(:game_server, {:start})

            Web.SnakeChannel.broadcast_state()

            perform_turn()
        end
    end

    def perform_turn do

        get_turn_state()
        |> retrieve_moves
        |> process_moves
        |> is_game_over
        |> next_turn
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

        for move <- moves,
            name = elem(move, 0),
            direction = elem(move, 1),
            position = Enum.find(normalized_board, fn cell -> cell[:snake] == name && cell[:state] == :head end),
            dest_coord = get_new_position_from_move(position.x, position.y, direction),
            dest_tile = Board.get_board_tile(dest_coord[:x], dest_coord[:y]) do
                cond do
                    dest_tile == nil || dest_tile.state == :body -> snake_dead(name, position.x, position.y)
                    dest_tile.state == :food -> grow_snake(name, position.x, position.y, dest_coord[:x], dest_coord[:y])
                    dest_tile.state == :empty -> move_snake(name, position.x, position.y, dest_coord[:x], dest_coord[:y])
                    dest_tile.state == :head -> collide_snake(name, position.x, position.y, dest_coord[:x], dest_coord[:y])
                end
        end
    end

    def move_snake(name, x, y, new_x, new_y) do

        Board.remove_snake(name)

        new_coords = Snakes.move(name, new_x, new_y)

        head = hd(new_coords)

        Board.set_board_tile(Enum.at(head, 0), Enum.at(head, 1), :head, name)

        if length(new_coords) > 0 do
            for coord <- tl(new_coords) do
                Board.set_board_tile(Enum.at(coord, 0), Enum.at(coord, 1), :body, name)
            end
        end
    end

    def grow_snake(name, x, y, new_x, new_y) do

        # Location of the food is added to snake corods list
        Snakes.grow(name, new_x, new_y)

        # Update board state to reflect new body/head and position
        Board.set_board_tile(x, y, :body, name)
        Board.set_board_tile(new_x, new_y, :head, name)
    end

    def snake_dead(name, x, y) do 

        # Remove all parts of this snake from the board
        Board.remove_snake(name)

        # Update health
        Snakes.set_snake_health(name, 0)
    end

    def collide_snake(name, x, y, new_x, new_y) do

        normalized_board = Board.get_normalized_board()

        dest_tile = Board.get_board_tile(new_x, new_y)

        dest_snake_len = length(Enum.filter(normalized_board, fn tile -> tile.snake == dest_tile.snake end))

        this_snake_len = length(Enum.filter(normalized_board, fn tile -> tile.snake == name end))

        cond do
            dest_snake_len > this_snake_len -> snake_dead(name, x, y)
            this_snake_len > dest_snake_len -> snake_dead(dest_tile.snake, new_x, new_y)
            true ->
                snake_dead(name, x, y)
                snake_dead(dest_tile.snake, new_x, new_y)
        end
    end

    def get_new_position_from_move(x, y, direction) do
        
        cond do
            direction == "up" -> [x: x, y: y-1]
            direction == "down" -> [x: x, y: y+1]
            direction == "left" -> [x: x+1, y: y]
            direction == "right" -> [x: x-1, y: y]
        end
    end

    def is_game_over(_moves) do
        
        length(Enum.filter(Web.Snakes.get_snakes(), fn snake -> snake.health_points > 0 end)) == 0
    end

    def next_turn(is_over) when is_over == true do

        end_game()
    end

    def next_turn(_is_over) do

         GenServer.cast(:game_server, {:turn})

         if :rand.uniform() < 0.1 do

            Board.add_food()
         end

         Web.SnakeChannel.broadcast_state()

        :timer.apply_after(:timer.seconds(1), Web.Game, :perform_turn, [])
    end

    def end_game do

        GenServer.call(:game_server, {:end})

        Web.SnakeChannel.broadcast_state()
    end
    
    # Server API

    def handle_call({:get}, _from, state) do

        {:reply, state, state}
    end

    def handle_call({:end}, _from, state) do

        {:reply, state, %{:state => :finished}}
    end

    def handle_cast({:init}, _state) do

        {:noreply, %{:turn => 0, :state => :starting}}
    end

    def handle_cast({:start}, _state) do

        cur_time = :os.timestamp()
        time_int = String.to_integer("#{elem(cur_time, 0)}#{elem(cur_time, 1)}")

        {:noreply, %{:turn => 1, :state => :started, :started_time => time_int }}
    end

    def handle_cast({:turn}, state) do

        {:noreply, Map.merge(state, %{:turn => state.turn + 1})}
    end
end