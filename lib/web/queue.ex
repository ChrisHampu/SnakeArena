defmodule Web.Queue do
    use GenServer

    def start_link(state, opts \\ []) do
        GenServer.start_link(__MODULE__, state, opts)
    end

    # Add an entry to the queue
    def add(snake) do
        GenServer.call(:queue_server, {:add, snake})

        
        Web.Game.try_new_game()
    end

    # Number of snakes in the queue
    def length() do
        GenServer.call(:queue_server, {:length})
    end

    # Pops all current entries in the queue and returns them
    def pull_all() do

       GenServer.call(:queue_server, {:pull}) 
    end

    # Returns the list without removing any entries
    def get_all() do

         GenServer.call(:queue_server, {:get}) 
    end

    # Server API

    def handle_call({:add, snake}, _from, state) do

        # Ensure a snake is not being added as a duplicate
        if is_nil(List.keyfind(state, elem(snake, 0), 0)) do

            new_state = [snake | state]

            {:reply, new_state, new_state}
        else
            {:reply, state, state}
        end
    end

    def handle_call({:length}, _from, state) do

        {:reply, length(state), state}
    end

    def handle_call({:pull}, _from, state) do

        {:reply, state, []}
    end

    def handle_call({:get}, _from, state) do

        {:reply, state, state}
    end
end