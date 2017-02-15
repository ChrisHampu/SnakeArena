defmodule Web.Game do
    use GenServer

    def start_link(state, opts \\ []) do
        GenServer.start_link(__MODULE__, state, opts)
    end

    # Add an entry to the queue
    def add() do
        
    end

    # Pops all current entries in the queue and returns them
    def pull_all() do
        
    end
end