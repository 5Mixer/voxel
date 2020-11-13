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

    public var vertexData:Array<Float> = [];
    public var indexData:Array<Int> = [];

    public var vertexBuffer:VertexBuffer;
    public var indexBuffer:IndexBuffer;

    public function new(wx, wy, wz) {
        this.wx = wx;
        this.wy = wy;
		this.wz = wz;
		
		blocks = Bytes.alloc(chunkSizeCubed);
		blocks.fill(0, chunkSizeCubed, 0);
		for(x in 0...chunkSize)
			for(z in 0...chunkSize)
				for(y in 0...Std.int(10*(1+Math.cos((wx*chunkSize+x)/20)+Math.sin((wz*chunkSize+z)/20))))
					setBlock(x,y,z,1);
    }
    
    inline public function getBlock(x, y, z) {
		return blocks.get(x*(chunkSizeSquared) + y*chunkSize + z);
	}
    inline public function setBlock(x, y, z, b) {
		blocks.set(x*(chunkSizeSquared) + y*chunkSize + z, b);
	}

	public function hasGeometry() {
		return vertexBuffer != null && indexBuffer != null && vertexBuffer.count() != 0;
	}
	public function destroyGeometry() {
		if (!hasGeometry())
			return;
		vertexBuffer.delete();
		indexBuffer.delete();
		vertexData = null;
		indexData = null;
		vertexBuffer = null;
		indexBuffer = null;
	}
}