package ;

import kha.Shaders;
import kha.graphics4.*;

class Scene {
	
	var structure:VertexStructure;
	var vertexBuffer:VertexBuffer;
	var indexBuffer:IndexBuffer;
	var pipeline:PipelineState;
	
	var mvpID:ConstantLocation;
	var textureID:TextureUnit;
	
	var camera:Camera;
	var chunks:Array<Chunk> = [];
	var createdChunks = [];
	var generator:WorldGenerator;

	var chunkGeomChanged = false; // Dirty flag for chunk loads and block changes.

	var prevCameraChunk = '';
	var chunksProcessedThisFrame = 0;

	var chunkCache:Chunk = null;

	static var radius = 2;
	static var loadedChunksPerDimension = radius * 2 + 1; // -radius, 0, +radius

	var cameraChunkX=0;
	var cameraChunkY=0;
	var cameraChunkZ=0;

	var chunkArrayOffsetX=0;
	var chunkArrayOffsetY=0;
	var chunkArrayOffsetZ=0;
	
	public function new(camera:Camera) {
		this.camera = camera;
		generator = new FlatWorldGenerator();

		// for (cx in 0...loadedChunksPerDimension)
		// 	for (cy in 0...loadedChunksPerDimension)
		// 		for (cz in 0...loadedChunksPerDimension)
		// 			chunks.push(null);
		
		// kha.Assets.images.sprites.generateMipmaps(0);
		
		setupPipeline();
	}

	public function getChunk(cx:Int, cy:Int, cz:Int) {
		if (cx-chunkArrayOffsetX+radius < 0 || cx-chunkArrayOffsetX+radius >= loadedChunksPerDimension)
			return null;
		if (cy-chunkArrayOffsetY+radius < 0 || cy-chunkArrayOffsetY+radius >= loadedChunksPerDimension)
			return null;
		if (cz-chunkArrayOffsetZ+radius < 0 || cz-chunkArrayOffsetZ+radius >= loadedChunksPerDimension)
			return null;
		return chunks[(cx-chunkArrayOffsetX+radius)*loadedChunksPerDimension*loadedChunksPerDimension+(cy-chunkArrayOffsetY+radius)*loadedChunksPerDimension+(cz-chunkArrayOffsetZ+radius)];
	}
	public function registerChunk(x:Int,y:Int,z:Int,chunk:Chunk) {
		chunks[(x-chunkArrayOffsetX+radius)*loadedChunksPerDimension*loadedChunksPerDimension+(y-chunkArrayOffsetY+radius)*loadedChunksPerDimension+(z-chunkArrayOffsetZ+radius)] = chunk;
	}

	inline function chunkMod(n:Int):Int {
		// Mod (%) normally wraps negative numbers so that -5 % 4 = -1. It should = 4
		return (n%Chunk.chunkSize + Chunk.chunkSize) % Chunk.chunkSize;
	}
	
	inline public function getBlock(x, y, z):Null<Int> {
		var chunk = getChunk(Math.floor(x / Chunk.chunkSize), Math.floor(y / Chunk.chunkSize), Math.floor(z / Chunk.chunkSize));
		if (chunk == null)
			return null;
		return chunk.getBlock(chunkMod(x), chunkMod(y), chunkMod(z));
	}
	function setBlock(x,y,z,b){
		var chunk = getChunk(Math.floor(x / Chunk.chunkSize), Math.floor(y / Chunk.chunkSize), Math.floor(z / Chunk.chunkSize));
		if (chunk == null)
			return;

		chunkGeomChanged = true;

		// Set neighboring chunks to dirty geom so that lighting, ao, etc is recalculated
		for (xOffset in -1...2)
			for (yOffset in -1...2)
				for (zOffset in -1...2)
					getChunk(Math.floor((x+xOffset) / Chunk.chunkSize), Math.floor((y+yOffset) / Chunk.chunkSize), Math.floor((z+zOffset) / Chunk.chunkSize)).dirtyGeometry = true;

		chunk.setBlock(chunkMod(x), chunkMod(y), chunkMod(z), b);
	}
	inline public function isAir(x:Int, y:Int, z:Int) {
		return getBlock(x,y,z) == null || getBlock(x,y,z) == 0;
	}
	inline public function isExposed(x:Int, y:Int, z:Int) {
		return getBlock(x,y,z) == null || getBlock(x,y,z) == 0;
	}
	
	function setupPipeline() {
		// Vertex structure
		structure = new VertexStructure();
		structure.add("pos", VertexData.Float3);
		structure.add("CubeGeometry.uv", VertexData.Float2);
		structure.add("colour", VertexData.Float3);
		
		// Pipeline
		pipeline = new PipelineState();
		pipeline.inputLayout = [structure];
		pipeline.fragmentShader = Shaders.block_frag;
		pipeline.vertexShader = Shaders.block_vert;
		
		pipeline.depthWrite = true;
		pipeline.depthMode = CompareMode.Less;
		
		pipeline.colorAttachmentCount = 1;
		pipeline.colorAttachments[0] = kha.graphics4.TextureFormat.RGBA32;
		pipeline.depthStencilAttachment = kha.graphics4.DepthStencilFormat.Depth16;
		pipeline.cullMode = Clockwise;
		
		pipeline.compile();
		
		// Graphics variables
		mvpID = pipeline.getConstantLocation("MVP");
		textureID = pipeline.getTextureUnit("textureSampler");
	}
	
	function shouldGenerateChunkGeometry(cx,cy,cz) {
		return (getChunk(cx+1,cy,cz) != null) && (getChunk(cx-1,cy,cz) != null) && (getChunk(cx,cy,cz+1) != null) && (getChunk(cx,cy,cz-1) != null)
			&& (getChunk(cx+1,cy,cz+1) != null) && (getChunk(cx+1,cy,cz-1) != null) && (getChunk(cx-1,cy,cz+1) != null) && (getChunk(cx-1,cy,cz-1) != null);
	}

	function refreshChunkArray() {
		chunks.sort(function(a,b){
			if (a.wx == b.wx)
				if (a.wy == b.wy)
					return a.wz - b.wz;
				else
					return a.wy - b.wy;
			return a.wx-b.wx;
		});
	}
	
	function constructChunkGeometry(chunk:Chunk) {
		if (chunk == null || (chunk.hasGeometry() && !chunk.dirtyGeometry))
			return;
		
		chunkCache = chunk;

		// if (!shouldGenerateChunkGeometry(chunk.wx, chunk.wy, chunk.wz)) {
		if (Math.abs(chunk.wx-cameraChunkX)>radius-1 || Math.abs(chunk.wz-cameraChunkZ)>radius-1){
			// chunk.destroyGeometry();
			return;
		}


		chunksProcessedThisFrame++;

		chunk.dirtyGeometry = false;

		// Arrays that the GPU buffers are constructed from
		var vertexData:Array<Float> = [];
		var indexData:Array<Int> = [];
				
		// Stores the current quads four AO values, so the quad may be index flipped if required
		var ao = new haxe.ds.Vector<Float>(4);

		var vertexIndex = 0;

		var chunkOriginWorldscaleX = chunk.wx * Chunk.chunkSize;
		var chunkOriginWorldscaleY = chunk.wy * Chunk.chunkSize;
		var chunkOriginWorldscaleZ = chunk.wz * Chunk.chunkSize;

		for (blockIndex in 0...Chunk.chunkSizeCubed) {
			var block = chunk.blocks.get(blockIndex);

			// Skip air
			if (block == 0)
				continue;
			
			var x = chunkOriginWorldscaleX + Math.floor(blockIndex/Chunk.chunkSizeSquared);
			var y = chunkOriginWorldscaleY + Math.floor(blockIndex/Chunk.chunkSize)%Chunk.chunkSize;
			var z = chunkOriginWorldscaleZ + blockIndex%Chunk.chunkSize;
			
			for (face in 0...6) {
				// For faces that face anything other than air, skip
				if (face == Side.Right && !isExposed(x+1,y,z))
					continue;
				
				if (face == Side.Left && !isExposed(x-1,y,z))
					continue;
				
				if (face == Side.Up && !isExposed(x,y+1,z))
					continue;
				
				if (face == Side.Down && !isExposed(x,y-1,z))
					continue;
				
				if (face == Side.Front && !isExposed(x,y,z+1))
					continue;
				
				if (face == Side.Back && !isExposed(x,y,z-1))
					continue;
				
				
				for (triangleVertex in 0...4) {
					var v = face*4 + triangleVertex; // v is the [0-24) vertices of the quad
					
					// position (xyz)
					vertexData.push(CubeGeometry.vertices[v*3+0]+x); // pos x
					vertexData.push(CubeGeometry.vertices[v*3+1]+y); // pos y
					vertexData.push(CubeGeometry.vertices[v*3+2]+z); // pos z
					
					// texture (CubeGeometry.uv)
					vertexData.push(CubeGeometry.uv[v*2]  *16/256);
					vertexData.push((CubeGeometry.uv[v*2+1]+block-1)*16/256);
					
					// colour (rgb)
					var light = 1.0;
					var side1 = false, side2 = false, corner = false;

					// Map the internal cube coordinates to -1 and 1 for ease of AO when comparing with nearby cubes
					var xVertexOffset = CubeGeometry.vertices[v*3+0] == 1 ? 1 : -1;
					var yVertexOffset = CubeGeometry.vertices[v*3+1] == 1 ? 1 : -1;
					var zVertexOffset = CubeGeometry.vertices[v*3+2] == 1 ? 1 : -1;
					
					// Left and right adjacency tests for AO
					if (face == Side.Left || face == Side.Right){
						side1 =  !isExposed(x + xVertexOffset, y + yVertexOffset, z                );
						side2 =  !isExposed(x + xVertexOffset, y                , z + zVertexOffset);
					}
					// Up and down adjacency tests for AO
					if (face == Side.Up || face == Side.Down){
						side1 =  !isExposed(x + xVertexOffset, y + yVertexOffset, z                );
						side2 =  !isExposed(x,                 y + yVertexOffset, z + zVertexOffset);
					}
					// Front and back adjacency tests for AO
					if (face == Side.Front || face == Side.Back){
						side1 =  !isExposed(x + xVertexOffset, y                , z + zVertexOffset);
						side2 =  !isExposed(x,                 y + yVertexOffset, z + zVertexOffset);
					}
					
					// Find corner for AO
					corner = !isExposed(x + xVertexOffset, y + yVertexOffset, z + zVertexOffset);
					
					// Absence of corner is irrelevant if both sides obscure corner
					if (side1 && side2)
						light = 0;
					else
						light = (3 - ((side1?1:0)+(side2?1:0)+(corner?1:0)))/3; // Subtract light linearly by number of adjacent blocks

					light = .8 + .2 * light;

					// Store this quad vertex in quad AO working array, so the quad may be flipped if it makes AO look nicer.
					ao[triangleVertex] = light;
					vertexData.push(light);
					vertexData.push(light);
					vertexData.push(light);
				}
				
				// Register quad as two triangles through index buffer
				// Flip if AO is backwards
				if (ao[0] + ao[2] > ao[1] + ao[3]) {
					indexData.push(vertexIndex+0);
					indexData.push(vertexIndex+1);
					indexData.push(vertexIndex+2);
					
					indexData.push(vertexIndex+0);
					indexData.push(vertexIndex+2);
					indexData.push(vertexIndex+3);
				}else{
					indexData.push(vertexIndex+1);
					indexData.push(vertexIndex+2);
					indexData.push(vertexIndex+3);
					
					indexData.push(vertexIndex+1);
					indexData.push(vertexIndex+3);
					indexData.push(vertexIndex+0);
				}
				vertexIndex += 4;
			}
		}

		var vertexByteSize = 8;
		// Load the generated vertex data into a buffer
		chunk.vertexBuffer = new VertexBuffer(Std.int(vertexData.length/vertexByteSize), structure, StaticUsage);
		var vertexBufferData = chunk.vertexBuffer.lock();
		for (i in 0...vertexData.length)
			vertexBufferData[i] = vertexData[i];
		chunk.vertexBuffer.unlock();
		
		// Load the generated index data into a buffer
		chunk.indexBuffer = new IndexBuffer(indexData.length, StaticUsage);
		var indexBufferData = chunk.indexBuffer.lock();
		for (i in 0...Std.int(indexData.length))
			indexBufferData[i] = indexData[i];
		chunk.indexBuffer.unlock();

		vertexData = null;
		indexData = null;
	}
	
	public function update() {
		cameraChunkX = Math.floor(camera.position.x/Chunk.chunkSize);
		cameraChunkY = Math.floor(camera.position.y/Chunk.chunkSize);
		cameraChunkZ = Math.floor(camera.position.z/Chunk.chunkSize);
		var cameraChunk = '$cameraChunkX,$cameraChunkY,$cameraChunkZ';
		
		if (cameraChunk != prevCameraChunk) {
			var index = 0;
			var newChunks = [];
			for (cx in -radius...radius+1)
				for (cy in -radius...radius+1)
					for (cz in -radius...radius+1)
						{
							var existingChunk = getChunk(cx+cameraChunkX,cy+cameraChunkY,cz+cameraChunkZ);
							if (existingChunk != null)
								newChunks[index] = (existingChunk);
							else
								newChunks[index] = (new Chunk(cameraChunkX+cx,cameraChunkY+cy,cameraChunkZ+cz, generator));

							index++;
						}
			chunks = newChunks;
			chunkArrayOffsetX = cameraChunkX;
			chunkArrayOffsetY = cameraChunkY;
			chunkArrayOffsetZ = cameraChunkZ;

			chunkGeomChanged = true;
			// for (x in -radius...radius+1)
			// 	for (y in -radius...radius+1)
			// 		for (z in -radius...radius+1)
			// 			if (getChunk(cameraChunkX+x,cameraChunkY+y,cameraChunkZ+z) == null) {
			// 				registerChunk(cameraChunkX+x,cameraChunkY+y,cameraChunkZ+z,new Chunk(cameraChunkX+x,cameraChunkY+y,cameraChunkZ+z, generator));
			// 				chunkGeomChanged = true;
			// 			}

			// for (chunk in chunks) {
			// 	if (Math.min(chunk.wx - cameraChunkX, Math.min(chunk.wy-cameraChunkY, chunk.wz - cameraChunkZ)) > radius) {
					// chunk.destroyGeometry();
					// chunks.remove('${chunk.wx},${chunk.wy},${chunk.wz}');
					// chunk = null;
			// 	}
			// }
		}
		
		
		if (chunkGeomChanged) {
			for (chunk in chunks) {
				constructChunkGeometry(chunk);
			}
		}
		prevCameraChunk = cameraChunk + "";
		chunksProcessedThisFrame = 0;
	}

	public function render(g:Graphics) {
		g.setPipeline(pipeline);
		
		g.setMatrix(mvpID, camera.getMVP());
		g.setTexture(textureID, kha.Assets.images.sprites);
		// g.setTextureParameters(textureID, Clamp, Clamp, TextureFilter.PointFilter, TextureFilter.PointFilter, MipMapFilter.LinearMipFilter);
		g.setTextureParameters(textureID, Clamp, Clamp, TextureFilter.PointFilter, TextureFilter.PointFilter, MipMapFilter.NoMipFilter);
		
		for (chunk in chunks) {
			if (chunk == null || !chunk.hasGeometry()) {
				continue;
			}
			g.setVertexBuffer(chunk.vertexBuffer);
			g.setIndexBuffer(chunk.indexBuffer);
			g.drawIndexedVertices();
		}
	}

	public function ray(place) {
		var look = camera.getLookVector().normalized();
		var stepSize = .1;
		var delta = look.mult(stepSize);
		var rayBlock = 0;
		var iterations = 0;
		var rayLength = 10;
		var rayPos = camera.position.mult(1);
		while (rayBlock == 0 && iterations++ < rayLength/stepSize) {
			rayPos = rayPos.add(delta);
			rayBlock = getBlock(Math.floor(rayPos.x), Math.floor(rayPos.y), Math.floor(rayPos.z));
		}

		if (iterations >= rayLength/stepSize)
			return; // Don't do anything if ray extends outside reach

		if (!place) {
			setBlock(Math.floor(rayPos.x), Math.floor(rayPos.y),Math.floor(rayPos.z), 0);
		}else{
			var rayEnd = rayPos.sub(delta);
			setBlock(Math.floor(rayEnd.x), Math.floor(rayEnd.y),Math.floor(rayEnd.z), 3);
		}
	}
}
