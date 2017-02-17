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

chan.on("state", state => {
    
    updateGameState(state);
});

function updateGameState(state) {

    if (state.state === "finished") {
        $('.status').innerHTML = "Round Finished";
        $('.time').innerHTML = "00:00";
        $('.turn-number').innerHTML = "1";
    } else if(state.state === "starting") {
        $('.status').innerHTML = "Round Starting";
        $('.time').innerHTML = "00:00";
    } else if (state.state === "started") {
        $('.status').innerHTML = "Round in Progress";
        $('.time').innerHTML = "00:00";
        $('.turn-number').innerHTML = state.turn;
    }
}