package ;

import haxe.io.Bytes;
import kha.graphics4.IndexBuffer;
import kha.graphics4.VertexBuffer;

class Chunk {
	public var blocks:Bytes;
	public var exposedRLE = []; //Starts with number exposed, then not, then exposed...

	public static inline var chunkSize = 40;
	public static inline var chunkSizeSquared = chunkSize * chunkSize;
	public static inline var chunkSizeCubed = chunkSize * chunkSize * chunkSize;
	var min = 0;
    var max = chunkSize-1;
    
    public var wx:Int;
    public var wy:Int;
    public var wz:Int;

    public var vertexBuffer:VertexBuffer;
    public var indexBuffer:IndexBuffer;

	public var dirtyGeometry = false;

    public function new(wx, wy, wz, worldGenerator) {
		blocks = Bytes.alloc(chunkSizeCubed);

		var runLengthExposed = true;
		
		loadForLocation(wx, wy, wz, worldGenerator);
	}
	public function loadForLocation(wx,wy,wz,worldGenerator:WorldGenerator) {
        this.wx = wx;
        this.wy = wy;
		this.wz = wz;
		
		for(x in 0...chunkSize)
			for(y in 0...chunkSize)
				for(z in 0...chunkSize) {
					var block = worldGenerator.getBlock(wx*chunkSize+x,wy*chunkSize+y,wz*chunkSize+z);
					// if (runLengthExposed == (block == 0)) {
					// 	exposedRLE[exposedRLE.length-1]++;
					// }else{
					// 	exposedRLE.push(1);
					// }
					setBlock(x,y,z,cast(block,Int));
				}
	}
    
    inline public function getBlock(x, y, z) {
		return blocks.get(x*chunkSizeSquared + y*chunkSize + z);
	}
    inline public function setBlock(x, y, z, b) {
		blocks.set(x*chunkSizeSquared + y*chunkSize + z, b);
		dirtyGeometry = true;
	}

	public function hasGeometry() {
		return vertexBuffer != null;
	}
	public function destroyGeometry() {
		if (!hasGeometry())
			return;
		vertexBuffer.delete();
		indexBuffer.delete();
		vertexBuffer = null;
		indexBuffer = null;
	}

	/* Index to location
	var x = chunkOriginWorldscaleX + Math.floor(blockIndex/Chunk.chunkSizeSquared);
	var y = chunkOriginWorldscaleY + Math.floor(blockIndex/Chunk.chunkSize)%Chunk.chunkSize;
	var z = chunkOriginWorldscaleZ + blockIndex%Chunk.chunkSize;
	*/
}