package ;

import hx.ws.Types;
import hx.ws.WebSocket;

class ServerConnection {
    var ws:WebSocket;
    var connected = false;
    public function new() {
        ws = new WebSocket("ws://127.0.0.1:4646");
        
        ws.onopen = function() {
            connected = true;
            
            ws.send("!worldRequest");
        }

        ws.onmessage = onMessage; 
    }
    public function sendChunk(chunk:Chunk) {
    }
    function onMessage(message:MessageType) {
        switch (message){
            case BytesMessage(content): {
            }
            case StrMessage(content): {
            }
        }
    };
}