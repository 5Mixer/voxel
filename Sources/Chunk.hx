package;

import haxe.Timer;
import haxe.io.Bytes;
import kha.graphics4.IndexBuffer;
import kha.graphics4.VertexBuffer;

class Chunk {
	var blocks:Bytes;

	public static inline var chunkSize = 32;
	public static inline var chunkSizeSquared = chunkSize * chunkSize;
	public static inline var chunkSizeCubed = chunkSize * chunkSize * chunkSize;

	public var pos:Vector3i;

	public var vertexBuffer:VertexBuffer;
	public var indexBuffer:IndexBuffer;

	public var dirtyGeometry = false;
	public var visible = false;

	var perlin:hxnoise.Perlin;

	public function new() {
        perlin = new hxnoise.Perlin();
	}

	public function loadForLocation(wx, wy, wz, worldGenerator:WorldGenerator) {
		pos = new Vector3i(wx, wy, wz);
		trace('Loading ${toString()}');

		var worldSpaceX = wx * chunkSize;
		var worldSpaceY = wy * chunkSize;
		var worldSpaceZ = wz * chunkSize;

		blocks = Bytes.alloc(12 + chunkSizeCubed);
		blocks.setInt32(0, wx);
		blocks.setInt32(4, wx);
		blocks.setInt32(8, wx);

		var start = Timer.stamp();

		if (worldSpaceY < -70) {
			for (x in 0...chunkSize)
				for (y in 0...chunkSize)
					for (z in 0...chunkSize)
						setBlockByIndex(x * chunkSizeSquared + y * chunkSize + z, BlockIdentifier.Grass);
		} else if (worldSpaceY > 30) {
			for (x in 0...chunkSize)
				for (y in 0...chunkSize)
					for (z in 0...chunkSize)
						setBlockByIndex(x * chunkSizeSquared + y * chunkSize + z, BlockIdentifier.Air);
		} else {
			for (x in 0...chunkSize)
				for (z in 0...chunkSize) {
					var height = perlin.OctavePerlin((worldSpaceX+x)/8,(worldSpaceZ+z)/8,.1, 3, .5, .25) * 50 - 20;
					for (y in 0...chunkSize) {
						// var block = 30 * Math.cos((x+z/2)/23) * Math.sin((x/4+z)/20) > y ? BlockIdentifier.Air : BlockIdentifier.Grass;
						var block = height < worldSpaceY + y ? BlockIdentifier.Air : BlockIdentifier.Grass;
						// var block = worldGenerator.getBlock(worldSpaceX + x, worldSpaceY + y, worldSpaceZ + z);
						setBlockByIndex(x * chunkSizeSquared + y * chunkSize + z, block);
					}
				}
		}
		
		trace('Took ${Timer.stamp() - start}s');

		visible = true;
		dirtyGeometry = true;
		trace('Loaded ${toString()}');
	}

	public function flagDirty() {
		trace('Flagged chunk ${toString()} dirty');
		dirtyGeometry = true;
	}

	public function isDataLoaded() {
		return blocks != null;
	}

	public function loadData(data:Bytes) {
		visible = true;
		pos = new Vector3i(data.getInt32(0), data.getInt32(4), data.getInt32(8));
		blocks = data;
		dirtyGeometry = true;
		trace('Loaded data for ${toString()}');
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

	public function toString() {
		return 'Chunk ${pos.toString()} [loaded: ${isDataLoaded()} visible: $visible]';
	}
}
