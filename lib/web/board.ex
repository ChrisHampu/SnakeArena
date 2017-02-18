defmodule Web.Board do
    use GenServer

    def start_link(state, opts \\ []) do
        GenServer.start_link(__MODULE__, state, opts)
    end

    # Client API
    def init_board() do
        x = max(8, :rand.uniform(12))
        y = max(8, :rand.uniform(12))

        board = Enum.map(1..x, fn x -> Enum.map(1..y, fn y -> %{:state => :empty, :snake => nil} end) end)

        GenServer.call(:board_server, {:put_board, %{board: board, width: x, height: y}})
    end

    def get_board() do

        GenServer.call(:board_server, {:get_board})
    end

    def get_normalized_board() do

        state = get_board()

        Enum.map(0..state.width-1, fn col ->
            Enum.map(0..state.height-1, fn row ->
                Map.merge(%{x: col, y: row}, Enum.at(Enum.at(state.board, col), row))
            end)
        end)
        |> Enum.flat_map(&(&1))
    end

    def get_board_tile(x, y) do

        GenServer.call(:board_server, {:get_board_tile, x, y})
    end

    # Set the tile at x/y and returns new board state
    def set_board_tile(x, y, state, snake \\ nil) do

        GenServer.call(:board_server, {:set_board_tile, x, y, state, snake})
    end

    def get_unoccupied_space() do

        normalized_board = get_normalized_board()

        GenServer.call(:board_server, {:get_space, normalized_board})
    end

    def remove_snake(name) do

        GenServer.call(:board_server, {:remove_snake, name})
    end

    def add_food() do
        
        tile = get_unoccupied_space()

        set_board_tile(tile.x, tile.y, :food, nil)
    end

    # Server API
    def handle_call({:put_board, board}, _from, state) do

        {:reply, board, Map.merge(state, board)}
    end

    def handle_call({:get_board}, _from, state) do

        {:reply, state, state}
    end

    def handle_call({:get_board_tile, x, y}, _from, state) do

        if x < 0 || x > state.width - 1 || y < 0 || y > state.height - 1 do
            {:reply, nil, state}
        else
            {:reply, Enum.at(Enum.at(state[:board], x), y), state}
        end
    end

    def handle_call({:set_board_tile, x, y, tile_state, snake}, _from, state) do

        new_board = List.replace_at(state[:board], x, List.replace_at(Enum.at(state[:board], x), y, %{:state => tile_state, :snake => snake}))

        new_state = Map.put(state, :board, new_board)

        {:reply, new_board, new_state}
    end

    def handle_call({:get_space, normalized_board}, _from, state) do

        # Create a list of empty spaces
        spaces = normalized_board
        |> Enum.filter(&(Map.get(&1, :state) == :empty))

        # TODO: Case when no empty spaces are left

        picked = :rand.uniform(length(spaces) - 1)
        {:reply, Enum.at(spaces, picked), state}
    end

    def handle_call({:remove_snake, name}, _from, state) do

        new_board = Enum.map(state[:board], fn col ->
            Enum.map(col, fn row ->
                cond do
                    row.snake == name -> Map.merge(row, %{:state => :empty, :snake => nil})
                    true -> row
                end
            end)
        end)

        new_state = Map.put(state, :board, new_board)

        {:reply, new_board, new_state}
    end
end