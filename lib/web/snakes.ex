defmodule Web.Snakes do
    use GenServer

    def start_link(state, opts \\ []) do
        GenServer.start_link(__MODULE__, state, opts)
    end

    # Client API
    def add(snakes) when is_list(snakes) do

        GenServer.cast(:snake_server, {:add_snakes, snakes})
    end

    def add(snake) do

        GenServer.cast(:snake_server, {:add_snake, snake})
    end

    def get_snakes do
        
        GenServer.call(:snake_server, {:get})
    end

    # Server API
    def handle_cast({:add_snakes, snakes}, state) do

        {:noreply, state ++ snakes}
    end

    def handle_cast({:add_snake, snake}, state) do

        {:reply, [snake | state]}
    end

    def handle_call({:get}, _from, state) do

        {:reply, state, state}
    end
end