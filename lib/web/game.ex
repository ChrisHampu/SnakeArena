defmodule Web.Game do
    use GenServer

    def start_link(state, opts \\ []) do
        GenServer.start_link(__MODULE__, state, opts)
    end

    # Initiates game logic using current queue
    def start_game() do
        
    end

    # Ends a game then initiates a timer to begin the next game
    def end_game() do

    end
end