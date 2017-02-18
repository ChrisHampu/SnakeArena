defmodule Web.Snakes do
    use GenServer

    alias Web.Board

    def start_link(state, opts \\ []) do
        GenServer.start_link(__MODULE__, state, opts)
    end

    # Client API
    def add(snakes) when is_list(snakes) do

        Enum.each(snakes, fn snake -> 
            position = hd(snake.coords)
            Board.set_board_tile(Enum.at(position, 0), Enum.at(position, 1), :head, snake.name) 
        end)

        GenServer.cast(:snake_server, {:add_snakes, snakes})
    end

    def add(snake) do

        Board.set_board_tile(snake.x, snake.y, :head, snake.name)

        GenServer.cast(:snake_server, {:add_snake, snake})
    end

    def grow(name, x, y) do
        
        GenServer.call(:snake_server, {:grow, name, [x, y]})
    end

    def move(name, x, y) do
        
        snake = GenServer.call(:snake_server, {:move, name, [x, y]})

        snake.coords
    end

    def get(name) do
        
        GenServer.call(:snake_server, {:get, name})
    end

    def get_snakes do
        
        GenServer.call(:snake_server, {:get})
    end

    def set_snake_health(name, health) do
        
        GenServer.call(:snake_server, {:set_health, name, health})
    end

    # Server API
    def handle_cast({:add_snakes, snakes}, state) do

        {:noreply, state ++ snakes}
    end

    def handle_cast({:add_snake, snake}, state) do

        {:reply, [snake | state]}
    end

    def handle_call({:grow, name, coord}, _from, state) do

        index = Enum.find_index(state, fn snake -> snake.name == name end)

        new_state = List.update_at(state, index, &Map.merge(&1, %{:coords => [coord | Map.get(&1, :coords)]}))

        {:reply, new_state, new_state}
    end

    def handle_call({:move, name, coord}, _from, state) do

        index = Enum.find_index(state, fn snake -> snake.name == name end)

        new_state = List.update_at(state, index, &Map.merge(&1, %{:coords => 
            cond do
                length(Map.get(&1, :coords)) == 1 -> [coord]
                true -> [coord | Map.get(&1, :coords)] -- [List.last(Map.get(&1, :coords))]
                #true -> [Enum.flat_map(tl(Map.get(&1, :coords)), fn x -> x end) | [coord]]
            end
        }))

        # Return the state for the specific snake
        {:reply, Enum.find(new_state, fn snake -> snake.name == name end), new_state}
    end

    def handle_call({:get, name}, _from, state) do

        {:reply, Enum.find(state, fn snake -> snake.name == name end), state}
    end

    def handle_call({:get}, _from, state) do

        {:reply, state, state}
    end

    def handle_call({:set_health, name, health}, _from, state) do

        index = Enum.find_index(state, fn snake -> snake.name == name end)

        new_state = List.update_at(state, index, &Map.merge(&1, %{:health_points => health}))

        {:reply, new_state, new_state}
    end
end