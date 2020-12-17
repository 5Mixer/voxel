const { trace } = require('console');
const WebSocket = require('ws');

const wss = new WebSocket.Server({ port: 4646 });

var chunks = {}

var chunkSize = 24;

const fastnoise = require('fastnoisejs')
const noise = fastnoise.Create(123)
 
noise.SetNoiseType(fastnoise.Perlin)

function getChunkData(cx,cy,cz) {
    if (chunks[cx+','+cy+','+cz] == undefined) {
        var data = Buffer.allocUnsafe(chunkSize*chunkSize*chunkSize+13);
        data.writeInt32LE(cx,0);
        data.writeInt32LE(cy,4);
        data.writeInt32LE(cz,8);
        data.writeUInt8(0,12)
        var index = 13;
        var allAir = true;
        for (let x = 0; x < chunkSize; x++) {
            var wx = x+cx*chunkSize;
            for (let y = 0; y < chunkSize; y++) {
                var wy = y+cy*chunkSize;
                for (let z = 0; z < chunkSize; z++) {
                    var wz = z+cz*chunkSize;

                    var block = noise.GetNoise(wx*2,wz*2)*40 > wy ? 2 : 0
                    if (block != 0)
                        allAir = false;
                    data.writeUInt8(block, index);
                    index++;
                }
            }
        }
       
        if (allAir) {
            data[12] = 1;
            data = data.subarray(0,13);
        }
        chunks[cx+','+cy+','+cz] = data;
    }

    return chunks[cx+','+cy+','+cz];
}
function setBlock(x,y,z,b){
    var cx = Math.floor(x/chunkSize);
    var cy = Math.floor(y/chunkSize);
    var cz = Math.floor(z/chunkSize);
    // var lx = x - cx*chunkSize;
    // var ly = y - cy*chunkSize;
    // var lz = z - cz*chunkSize;
    var chunk = chunks[cx+','+cy+','+cz];
    if (chunk != null) {
        chunk[12] = 0;// TODO: Create the rest of the chunk
        chunk[chunkMod(x)*chunkSize*chunkSize+chunkMod(y)*chunkSize+chunkMod(z)] = b;
    }
}
function chunkMod(n) {
    // Mod (%) normally wraps negative numbers so that -5 % 4 = -1. It should = 4
    return (n%chunkSize + chunkSize) % chunkSize;
}

wss.on('connection', function connection(ws) {
    console.log("New connection");
    
    ws.on('message', function incoming(message) {

        if (typeof message == "string"){
            var split = message.split(',');
            var packetType = split[0];

            if (packetType=='c')
                ws.send(getChunkData(parseInt(split[1]), parseInt(split[2]), parseInt(split[3])));
            if (packetType=='b'){
                setBlock(parseInt(split[1]), parseInt(split[2]), parseInt(split[3]), parseInt(split[4]));
                wss.clients.forEach(function each(client) {
                    if (client.readyState === WebSocket.OPEN && client !== ws) {
                        client.send(message);
                    }
                });
            }
        }
    })
})
