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

let boardConstraints = null;

chan.on("state", state => {

    if (state.board) {
    
        if (state.state === "starting" || !boardConstraints) {
            drawBoard(state.board);
        }

        drawTokens(state.board);
    }

    if (state.state) {
        updateGameState(state.state);
    }
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

function drawBoard(board) {
    
    const gameContainer = $(".field");
    const gameBoard = $("#game_board");
    const rectHolder = $("#game_rect");

    rectHolder.innerHTML = "";

    const boardWidth = gameContainer.clientWidth;
    const boardHeight = gameContainer.clientHeight;

    gameBoard.style.height = boardHeight;
    gameBoard.style.width = boardWidth;

    const wScale = boardWidth / (board.width + 1 || 1);
    const hScale = boardHeight / (board.height + 1 || 1);

    let startX = wScale / 2;
    let startY = hScale / 2;

    for (var i = 0; i < board.height; i++) {

        for (var j = 0; j < board.width; j++) {

            let rekt = makeRectangle(startX, startY, wScale, hScale, "rgba(0,0,0,0)", "rgba(0, 0, 0, 1)");

            rectHolder.appendChild(rekt);

            startX += wScale;
        }

        startY += hScale;
        startX = wScale / 2;
    }

    boardConstraints = {
        boardWidth,
        boardHeight,
        wScale,
        hScale,
        startX: wScale / 2,
        startY: hScale / 2,
        gameBoard
    };
}

function drawTokens(board_state) {

    const board = board_state.board;

    const holder = $("#game_tokens");

    holder.innerHTML = "";

    for (var i = 0; i < board_state.width; i++) {

        for (var j = 0; j < board_state.height; j++) {
            
            const token = board[i][j];

            if (token.state !== "empty") {

                let hitX = boardConstraints.startX + i * boardConstraints.wScale;
                let hitY = boardConstraints.startY + j * boardConstraints.hScale;

                let rekt = makeRectangle(hitX, hitY, boardConstraints.wScale, boardConstraints.hScale, "rgba(255,255,255,1)", "rgba(0, 0, 0, 1)");

                holder.appendChild(rekt);
            }
        }
    }
}

const makeRectangle = (x, y, w, h, c, s) => {
  var rect = document.createElementNS("http://www.w3.org/2000/svg", "rect"); 

  rect.setAttribute("x", x);
  rect.setAttribute("y", y);
  rect.setAttribute("width", w);
  rect.setAttribute("height", h);

  rect.style.stroke = s || "#000000";
  rect.style.strokeWidth = 2;
  rect.style.fill = c || "#000000";

  return rect; 
}

const makeCircle = (x, y, r, c) => {

   var circ = document.createElementNS("http://www.w3.org/2000/svg", "circle"); 

    circ.setAttribute("cx", x);
    circ.setAttribute("cy", y);
    circ.setAttribute("r", r);

    circ.setAttribute("fill", c || "#ffffff");

   return circ;
}