package ;

import haxe.display.JsonModuleTypes.JsonClassKindKind;
import kha.graphics4.CompareMode;
import kha.math.Vector3;
import kha.graphics4.TextureUnit;
import kha.graphics4.ConstantLocation;
import kha.Shaders;
import kha.graphics4.VertexStructure;
import kha.graphics4.VertexData;
import kha.graphics4.TextureFilter;
import kha.graphics4.MipMapFilter;
import kha.graphics4.PipelineState;
import kha.graphics4.IndexBuffer;
import kha.graphics4.VertexBuffer;
import kha.graphics4.Graphics;

class Scene {
	static var blockStructure = [
		1, 0, 0, // right
		1, 1, 0,
		1, 1, 1,
		1, 0, 1,
		
		0, 0, 1, // left
		0, 1, 1,
		0, 1, 0,
		0, 0, 0,
		
		1, 1, 0, // top
		0, 1, 0,
		0, 1, 1,
		1, 1, 1,
		
		1, 0, 1, // bottom
		0, 0, 1,
		0, 0, 0,
		1, 0, 0,

		0, 0, 1, // front
		1, 0, 1,
		1, 1, 1,
		0, 1, 1,

		0, 1, 0, // back
		1, 1, 0,
		1, 0, 0,
		0, 0, 0
	];
	static var uv = [
		1, 1, //right
		1, 0,
		0, 0,
		0, 1,
		
		2, 1, //left
		2, 0,
		1, 0,
		1, 1,
		
		3, 0,
		2, 0,
		2, 1,
		3, 1, //Up/top
		
		4, 0,
		3, 0,
		3, 1,
		4, 1, //Bottom/down
		
		4, 1,
		5, 1, //front
		5, 0,
		4, 0,
		
		6, 0,
		5, 0,
		5, 1, //back
		6, 1
	];
	
	var structure:VertexStructure;
	var vertexBuffer:VertexBuffer;
	var indexBuffer:IndexBuffer;
	var pipeline:PipelineState;
	
	var mvpID:ConstantLocation;
	var textureID:TextureUnit;
	
	var camera:Camera;
	var chunks:Map<String,Chunk> = new Map<String,Chunk>();
	var generator:WorldGenerator;
	
	public function new(camera:Camera) {
		this.camera = camera;
		generator = new FlatWorldGenerator();
		
		kha.Assets.images.sprites.generateMipmaps(3);
		
		setupPipeline();
	}
	
	public function getChunk(cx:Int, cy:Int, cz:Int) {
		return chunks.get('$cx,$cy,$cz');
	}
	public function registerChunk(chunk:Chunk) {
		chunks.set(chunk.wx+','+chunk.wy+','+chunk.wz, chunk);
	}

	inline function chunkMod(n:Int,chunkSize:Int):Int {
		// Mod (%) normally wraps negative numbers so that -5 % 4 = -1. It should = 4
		return (n%chunkSize + chunkSize) % chunkSize;
	}
	
	inline public function getBlock(x, y, z):Null<Int> {
		var chunk = getChunk(Math.floor(x / Chunk.chunkSize), Math.floor(y / Chunk.chunkSize), Math.floor(z / Chunk.chunkSize));
		if (chunk == null)
			return null;
		return chunk.getBlock(chunkMod(x, Chunk.chunkSize), chunkMod(y, Chunk.chunkSize), chunkMod(z, Chunk.chunkSize));
	}
	function setBlock(x,y,z,b){
		var chunk = getChunk(Math.floor(x / Chunk.chunkSize), Math.floor(y / Chunk.chunkSize), Math.floor(z / Chunk.chunkSize));
		if (chunk == null)
			return;

		// Set neighboring chunks to dirty geom so that lighting, ao, etc is recalculated
		for (xOffset in -1...2)
			for (yOffset in -1...2)
				for (zOffset in -1...2)
					getChunk(Math.floor((x+xOffset) / Chunk.chunkSize), Math.floor((y+yOffset) / Chunk.chunkSize), Math.floor((z+zOffset) / Chunk.chunkSize)).dirtyGeometry = true;

		chunk.setBlock(chunkMod(x, Chunk.chunkSize), chunkMod(y, Chunk.chunkSize), chunkMod(z, Chunk.chunkSize), b);
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
		structure.add("uv", VertexData.Float2);
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
		camera.recalculateMVP();
		textureID = pipeline.getTextureUnit("textureSampler");
	}
	
	function shouldGenerateChunkGeometry(cx,cy,cz) {
		return (getChunk(cx+1,cy,cz) != null) && (getChunk(cx-1,cy,cz) != null) && (getChunk(cx,cy,cz+1) != null) && (getChunk(cx,cy,cz-1) != null)
			&& (getChunk(cx+1,cy,cz+1) != null) && (getChunk(cx+1,cy,cz-1) != null) && (getChunk(cx-1,cy,cz+1) != null) && (getChunk(cx-1,cy,cz-1) != null);
	}
	
	function constructChunkGeometry(chunk:Chunk) {
		if (!shouldGenerateChunkGeometry(chunk.wx, chunk.wy, chunk.wz)) {
			return;
		}
		if (chunk.hasGeometry() && !chunk.dirtyGeometry)
			return;

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
					vertexData.push(blockStructure[v*3+0]+x); // pos x
					vertexData.push(blockStructure[v*3+1]+y); // pos y
					vertexData.push(blockStructure[v*3+2]+z); // pos z
					
					// texture (uv)
					vertexData.push(uv[v*2]  *16/256);
					vertexData.push((uv[v*2+1]+block-1)*16/256);
					
					// colour (rgb)
					var light = 1.0;
					var side1 = false, side2 = false, corner = false;

					// Map the internal cube coordinates to -1 and 1 for ease of AO when comparing with nearby cubes
					var xVertexOffset = blockStructure[v*3+0] == 1 ? 1 : -1;
					var yVertexOffset = blockStructure[v*3+1] == 1 ? 1 : -1;
					var zVertexOffset = blockStructure[v*3+2] == 1 ? 1 : -1;
					
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
		var cameraChunkX = Math.floor(camera.position.x/Chunk.chunkSize);
		var cameraChunkY = Math.floor(camera.position.y/Chunk.chunkSize);
		var cameraChunkZ = Math.floor(camera.position.z/Chunk.chunkSize);
		
		var radius = 4;
		for (x in -radius...radius+1)
			for (y in -radius...radius+1)
				for (z in -radius...radius+1)
					if (getChunk(cameraChunkX+x,cameraChunkY+y,cameraChunkZ+z) == null) {
						registerChunk(new Chunk(cameraChunkX+x,cameraChunkY+y,cameraChunkZ+z, generator));
					}
		
		for (chunk in chunks.iterator()) {
			if (Math.min(chunk.wx - cameraChunkX, Math.min(chunk.wy-cameraChunkY, chunk.wz - cameraChunkZ)) > radius) {
				chunk.destroyGeometry();
				chunks.remove('${chunk.wx},${chunk.wy},${chunk.wz}');
				chunk = null;
			}
		}
		
		for (chunk in chunks.iterator()) {
			constructChunkGeometry(chunk);
		}
	}

	public function render(g:Graphics) {
		g.setPipeline(pipeline);
		
		g.setMatrix(mvpID, camera.mvp);
		g.setTexture(textureID, kha.Assets.images.sprites);
		g.setTextureParameters(textureID, Clamp, Clamp, TextureFilter.PointFilter, TextureFilter.PointFilter, MipMapFilter.LinearMipFilter);
		
		for (chunk in chunks) {
			if (!chunk.hasGeometry())
				continue;
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
