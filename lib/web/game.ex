defmodule Web.Game do
    use GenServer
    alias Web.Queue

    def start_link(state, opts \\ []) do
        GenServer.start_link(__MODULE__, state, opts)
    end

    # Initiates game logic using current queue
    def start() do

        queue = Queue.pull_all()
    end

    # Ends a game then initiates a timer to begin the next game
    def end() do

    end
end