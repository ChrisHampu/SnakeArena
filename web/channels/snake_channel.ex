defmodule Web.SnakeChannel do
  use Phoenix.Channel

    def join("snake", message, socket) do

        send self(), {:after_join, message}

        {:ok, socket}
    end

    def handle_info({:after_join, _msg}, socket) do

        state = Web.Game.get_game_state()

        push socket, "join", state

        {:noreply, socket}
    end
end