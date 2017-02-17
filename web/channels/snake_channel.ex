defmodule Web.SnakeChannel do
  use Phoenix.Channel

    def join("snake", message, socket) do

        send self(), {:after_join, message}

        {:ok, socket}
    end

    def handle_info({:after_join, _msg}, socket) do

        push socket, "state", Web.Game.get_game_state()

        {:noreply, socket}
    end

    def broadcast_state do
        
        Web.Endpoint.broadcast "snake", "state", Web.Game.get_game_state()
    end
end