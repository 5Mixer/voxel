package ;

import haxe.io.Bytes;
import kha.graphics4.IndexBuffer;
import kha.graphics4.VertexBuffer;

class Chunk {
	public var blocks:Bytes;

	public static inline var chunkSize = 20;
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
        this.wx = wx;
        this.wy = wy;
		this.wz = wz;
		
		blocks = Bytes.alloc(chunkSizeCubed);
		// blocks.fill(0, chunkSizeCubed, 0);
		for(x in 0...chunkSize)
			for(y in 0...chunkSize)
				for(z in 0...chunkSize)
					setBlock(x,y,z,worldGenerator.getBlock(wx*chunkSize+x,wy*chunkSize+y,wz*chunkSize+z));
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
}