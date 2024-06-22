package;

import haxe.io.Bytes;
import kha.graphics4.IndexBuffer;
import kha.graphics4.VertexBuffer;

class Chunk {
	public var blocks:Bytes;

	public static inline var chunkSize = 32;
	public static inline var chunkSizeSquared = chunkSize * chunkSize;
	public static inline var chunkSizeCubed = chunkSize * chunkSize * chunkSize;

	public var pos:Vector3i = new Vector3i(0,0,0);

	public var vertexBuffer:VertexBuffer;
	public var indexBuffer:IndexBuffer;

	public var dirtyGeometry = false;
	public var visible = false;

	public function new() {}

	public function loadForLocation(wx, wy, wz, worldGenerator:WorldGenerator) {
		pos = new Vector3i(wx, wy, wz);

		var worldSpaceX = wx * chunkSize;
		var worldSpaceY = wy * chunkSize;
		var worldSpaceZ = wz * chunkSize;

		for (x in 0...chunkSize)
			for (y in 0...chunkSize)
				for (z in 0...chunkSize) {
					var block = worldGenerator.getBlock(worldSpaceX + x, worldSpaceY + y, worldSpaceZ + z);
					setBlockByIndex(x * chunkSizeSquared + y * chunkSize + z, block);
				}

		dirtyGeometry = true;
	}

	public function loadData(data:Bytes) {
		visible = true;
		pos = new Vector3i(data.getInt32(0), data.getInt32(4), data.getInt32(8));
		blocks = data;
		dirtyGeometry = true;
	}

	inline public function getBlock(x, y, z) {
		return blocks.get(12 + (x * chunkSizeSquared + y * chunkSize + z));
	}

	inline public function getBlockByIndex(index) {
		return blocks.get(12 + index);
	}
	
	inline public function setBlockByIndex(index, block) {
		return blocks.set(12 + index, block);
	}

	inline public function setBlock(x, y, z, b) {
		blocks.set(12 + (x * chunkSizeSquared + y * chunkSize + z), b);
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
