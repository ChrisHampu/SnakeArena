const $ = (selector) => document.querySelectorAll(selector)[0];

let socket = new Phoenix.Socket("/socket", {
    logger: ((kind, msg, data) => { console.log(`${kind}: ${msg}`, data) })
});

socket.connect();

socket.onOpen(console.log);
socket.onError(console.log);
socket.onClose(console.log);

var chan = socket.channel("snake", {});

chan.join().receive("ok", () => {});

chan.onError(e => console.log("something went wrong", e));
chan.onClose(e => console.log("channel closed", e));

chan.on("join", state => {
    
    updateGameState(state);
});

function updateGameState(state) {

    if (state.state === "finished") {
        $('.status').innerHTML = "Round Finished";
        $('.time').innerHTML = "00:00";
    }
}