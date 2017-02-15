defmodule Web.Board do
    use GenServer

    def start_link(state, opts \\ []) do
        GenServer.start_link(__MODULE__, state, opts)
    end

    # Client API
    def init_board() do
        x = max(8, :rand.uniform(12))
        y = max(8, :rand.uniform(12))

        board = Enum.map(1..x, fn x -> Enum.map(1..y, fn y -> :empty end) end)

        GenServer.call(:board_server, {:put_board, %{board: board, width: x, height: y}})
    end

    def get_board() do

        GenServer.call(:board_server, {:get_board})
    end

    def get_board_tile(x, y) do

        GenServer.call(:board_server, {:get_board_tile, x, y})
    end

    # Set the tile at x/y and returns new board state
    def set_board_tile(x, y, value) do

        GenServer.call(:board_server, {:set_board_tile, x, y, value})
    end

    # Server API
    def handle_call({:put_board, board}, _from, state) do

        {:reply, board, Map.merge(state, board)}
    end

    def handle_call({:get_board}, _from, state) do

        {:reply, state[:board], state}
    end

    def handle_call({:get_board_tile, x, y}, _from, state) do

        {:reply, Enum.at(Enum.at(state[:board], x), y), state}
    end

    def handle_call({:set_board_tile, x, y, value}, _from, state) do

        new_board = List.replace_at(state[:board], x, List.replace_at(Enum.at(state[:board], x), y, value))

        new_state = Map.put(state, :board, new_board)

        {:reply, new_board, new_state}
    end
end