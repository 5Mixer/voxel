package ;

import kha.graphics4.IndexBuffer;
import kha.graphics4.VertexBuffer;

class Chunk {
	public var blocks:Array<Int> = [];

	public static inline var chunkSize = 128;
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
		
		// Bytes.alloc(chunkSize * chunkSize * chunkSize).fill;

		for (x in 0...chunkSize)
			for (y in 0...chunkSize)
				for (z in 0...chunkSize) {
					blocks.push(wy*chunkSize+y<2?1:0);
					// blocks.push(wy*chunkSize+y<Math.abs(Math.sin((wx*chunkSize+x)/15)*5+Math.cos((wz*chunkSize+z)/15)*5)?1:0);
					// blocks.push(wy*chunkSize+y<(.5+Math.sin((wx*chunkSize+x)/10)*5)?1:0);
					// blocks.push(wy*chunkSize+y<(.5+Math.sin((wx*chunkSize+x)/10)*5)?1:0);
					// blocks.push(Math.random()>.5?1:0);
				}
    }
    
    inline public function getBlock(x, y, z) {
		return blocks[x*(chunkSize*chunkSize) + y*chunkSize + z];
	}
    inline public function setBlock(x, y, z, b) {
		blocks[x*(chunkSize*chunkSize) + y*chunkSize + z] = b;
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