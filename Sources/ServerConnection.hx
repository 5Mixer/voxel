package ;

import haxe.io.Bytes;
import hx.ws.Types;
import hx.ws.WebSocket;

class ServerConnection {
    var ws:WebSocket;
    var connected = false;
    public var receiveChunk:(Bytes) -> Void;
    public var receiveBlock:(x:Int,y:Int,z:Int,b:Int) -> Void;
    var messageQueue = [];
    public function new() {
        ws = new WebSocket("ws://127.0.0.1:4646");
        
        ws.onopen = function() {
            connected = true;
            
            for (message in messageQueue)
                ws.send(message);
        }

        ws.onmessage = onMessage; 
    }
    public function requestChunk(cx:Int,cy:Int,cz:Int) {
        send('c,$cx,$cy,$cz');
    }
    public function sendBlock(x:Int,y:Int,z:Int,b:Int) {
        send('b,$x,$y,$z,$b');
    }
    function send(message) {
        if (connected)
            ws.send(message);
        else 
            messageQueue.push(message);
    }
    function onMessage(message:MessageType) {
        switch (message){
            case BytesMessage(content): {
                receiveChunk(content.readAllAvailableBytes());
            }
            case StrMessage(content): {
                var args = content.split(',');
                if (args[0] == 'b') {
                    receiveBlock(Std.parseInt(args[1]), Std.parseInt(args[2]), Std.parseInt(args[3]), Std.parseInt(args[4]));
                }
            }
        }
    };
}