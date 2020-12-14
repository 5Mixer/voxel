package ;

import haxe.io.Bytes;
import kha.graphics4.IndexBuffer;
import kha.graphics4.VertexBuffer;

class Chunk {
	public var blocks:Bytes;

	public static inline var chunkSize = 24;
	public static inline var chunkSizeSquared = chunkSize * chunkSize;
	public static inline var chunkSizeCubed = chunkSize * chunkSize * chunkSize;
    
    public var wx:Int;
    public var wy:Int;
    public var wz:Int;

    public var vertexBuffer:VertexBuffer;
    public var indexBuffer:IndexBuffer;

	public var dirtyGeometry = false;
	public var visible = true;

    public function new(wx, wy, wz) {
		blocks = Bytes.alloc(chunkSizeCubed);
	}
	public function loadForLocation(wx,wy,wz,worldGenerator:WorldGenerator) {
        this.wx = wx;
        this.wy = wy;
		this.wz = wz;

		var worldSpaceX = wx * chunkSize;
		var worldSpaceY = wy * chunkSize;
		var worldSpaceZ = wz * chunkSize;
		
		for(x in 0...chunkSize)
			for(y in 0...chunkSize)
				for(z in 0...chunkSize) {
					var block = worldGenerator.getBlock(worldSpaceX+x, worldSpaceY+y, worldSpaceZ+z);
					blocks.set(x*chunkSizeSquared + y*chunkSize + z, block);
				}

		dirtyGeometry = true;
	}
	public function loadData(data:Bytes) {
		visible = true;
		wx = data.getInt32(0);
		wy = data.getInt32(4);
		wz = data.getInt32(8);
		if (data.get(12) == 1) {
			visible = false;
		}else{
			blocks.blit(0, data, 13, chunkSizeCubed);
		}
		dirtyGeometry = true;
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