defmodule Web.Queue do
    use GenServer

    def start_link(state, opts \\ []) do
        GenServer.start_link(__MODULE__, state, opts)
    end

    # Add an entry to the queue
    def add(snake) do
        GenServer.cast(:queue_server, {:add, snake})
    end

    # Number of snakes in the queue
    def length() do
        GenServer.call(:queue_server, {:length})
    end

    # Pops all current entries in the queue and returns them
    def pull_all() do

       GenServer.call(:queue_server, {:pull}) 
    end

    # Server API

    def handle_cast({:add, snake}, _from, state) do

        {:noreply, [snake | state]}
    end

    def handle_call({:length, board}, _from, state) do

        {:reply, length(state), state}
    end

    def handle_call({:pull, board}, _from, state) do

        {:reply, state, []}
    end
end