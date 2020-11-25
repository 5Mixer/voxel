const WebSocket = require('ws');

const wss = new WebSocket.Server({ port: 4646 });

wss.on('connection', function connection(ws) {
    console.log("New connection");
    
    ws.on('message', function incoming(message) {

        if (typeof message != "string"){
            worlds[ws.world] = message;

            wss.clients.forEach(function each(client) {
                if (client.readyState === WebSocket.OPEN && client !== ws) {
                    client.send(message);
                }
            });
        }
    })
})
