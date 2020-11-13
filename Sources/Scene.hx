package ;

import kha.math.Vector3;
import kha.graphics5_.MipMapFilter;
import kha.graphics5_.TextureFilter;
import kha.graphics4.TextureUnit;
import kha.graphics5_.CompareMode;
import kha.math.FastVector3;
import kha.math.FastMatrix4;
import kha.graphics4.ConstantLocation;
import kha.Shaders;
import kha.graphics5_.VertexData;
import kha.graphics4.VertexStructure;
import kha.graphics4.PipelineState;
import kha.graphics4.IndexBuffer;
import kha.graphics4.VertexBuffer;
import kha.graphics4.Graphics;

class Scene {
	static var blockStructure = [
		0, 1, 0,
		1, 1, 0,
		1, 0, 0,
		0, 0, 0,
		
		0, 0, 1,
		1, 0, 1,
		1, 1, 1,
		0, 1, 1,
		
		1, 0, 0,
		1, 1, 0,
		1, 1, 1,
		1, 0, 1,
		
		1, 1, 0, //top
		0, 1, 0,
		0, 1, 1,
		1, 1, 1,
		
		1, 0, 1,
		0, 0, 1,
		0, 0, 0,
		1, 0, 0,
		
		0, 0, 1,
		0, 1, 1,
		0, 1, 0,
		0, 0, 0
	];
	static var uv = [
		1, 0,
		0, 0,
		0, 1,
		1, 1,
		
		1, 1,
		2, 1,
		2, 0,
		1, 0,
		
		3, 1,
		3, 0,
		2, 0,
		2, 1,
		
		4, 1,
		4, 0,
		3, 0,
		3, 1,
		
		5, 1,
		5, 0,
		4, 0,
		4, 1,
		
		6, 1,
		6, 0,
		5, 0,
		5, 1
	];
	
	var structure:VertexStructure;
	var vertexBuffer:VertexBuffer;
	var indexBuffer:IndexBuffer;
	var pipeline:PipelineState;
	
	var mvp:FastMatrix4;
	var mvpID:ConstantLocation;
	var textureID:TextureUnit;
	
	var camera:Camera;
	// var chunks:Array<Chunk> = new Array<Chunk>();
	var chunks:Map<String,Chunk> = new Map<String,Chunk>();
	
	public function new(camera:Camera) {
		this.camera = camera;
		
		kha.Assets.images.sprites.generateMipmaps(3);
		
		setupPipeline();
		
		constructGeometry();
	}
	
	public function getChunk(cx:Int, cy:Int, cz:Int) {
		return chunks.get('$cx,$cy,$cz');
		// for (chunk in chunks)
		// 	if (chunk.wx == cx && chunk.wy == cy && chunk.wz == cz)
		// 		return chunk;
		
		// return null;
	}
	public function registerChunk(chunk:Chunk) {
		chunks.set(chunk.wx+','+chunk.wy+','+chunk.wz, chunk);
	}
	
	inline public function getBlock(x, y, z) {
		var chunk = getChunk(Math.floor(x / Chunk.chunkSize), Math.floor(y / Chunk.chunkSize), Math.floor(z / Chunk.chunkSize));
		if (chunk == null)
			return null;
		return chunk.getBlock(Std.int(Math.abs(x % Chunk.chunkSize)), Std.int(Math.abs(y % Chunk.chunkSize)), Std.int(Math.abs(z % Chunk.chunkSize)));
	}
	function setBlock(x,y,z,b){
		var chunk = getChunk(Math.floor(x / Chunk.chunkSize), Math.floor(y / Chunk.chunkSize), Math.floor(z / Chunk.chunkSize));
		if (chunk == null)
			return;
		chunk.setBlock(Std.int(Math.abs(x % Chunk.chunkSize)), Std.int(Math.abs(y % Chunk.chunkSize)), Std.int(Math.abs(z % Chunk.chunkSize)), b);
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
		// pipeline.cullMode = Clockwise;
		
		pipeline.compile();
		
		// Graphics variables
		mvpID = pipeline.getConstantLocation("MVP");
		calculateMVP();
		textureID = pipeline.getTextureUnit("textureSampler");
	}
	
	function isChunkSurrounded(cx,cy,cz) {
		return (getChunk(cx+1,cy,cz) != null) && (getChunk(cx-1,cy,cz) != null) && (getChunk(cx,cy,cz+1) != null) && (getChunk(cx,cy,cz-1) != null)
			&& (getChunk(cx+1,cy,cz+1) != null) && (getChunk(cx+1,cy,cz-1) != null) && (getChunk(cx-1,cy,cz+1) != null) && (getChunk(cx-1,cy,cz-1) != null);
	}
	
	function constructChunkGeometry(chunk:Chunk) {
		if (!isChunkSurrounded(chunk.wx, chunk.wy, chunk.wz)) {
			return;
		}
		if (chunk.hasGeometry())
			return;
		chunk.vertexData = [];
		chunk.indexData = [];

		var vertexIndex = 0;
		var blockIndex = 0;

		var _facesProduced = 0;

		for (block in chunk.blocks) {
			// Skip air
			if (block == 0) {
				blockIndex++;
				continue;
			}
			
			var x = (chunk.wx * Chunk.chunkSize) + (Math.floor(blockIndex/(Chunk.chunkSize*Chunk.chunkSize)));
			var y = (chunk.wy * Chunk.chunkSize) + (Math.floor(blockIndex/Chunk.chunkSize)%Chunk.chunkSize);
			var z = (chunk.wz * Chunk.chunkSize) + (blockIndex%Chunk.chunkSize);
			
			for (face in 0...6) {
				// For faces that face anything other than air, skip
				if (face == 0 && !isExposed(x,y,z-1)) // Right
					continue;
				
				if (face == 1 && !isExposed(x,y,z+1)) // Left
					continue;
				
				if (face == 2 && !isExposed(x+1,y,z)) // Front (facing camera)
					continue;
				
				if (face == 3 && !isExposed(x,y+1,z)) // Top
					continue;
				
				if (face == 4 && !isExposed(x,y-1,z)) // Under/bottom
					continue;
				
				if (face == 5 && !isExposed(x-1,y,z)) // Back
					continue;
				
				var ao:Array<Float> = [];
				
				for (triangleVertex in 0...4) {
					var v = face*4 + triangleVertex; // v is the [0-24) vertices of the quad
					
					// position (xyz)
					var position = new Vector3(blockStructure[v*3+0]+x, blockStructure[v*3+1]+y, blockStructure[v*3+2]+z);
					
					chunk.vertexData.push(position.x);
					chunk.vertexData.push(position.y);
					chunk.vertexData.push(position.z);
					
					// texture (uv)
					chunk.vertexData.push(uv[v*2]  *16/256);
					chunk.vertexData.push((uv[v*2+1]+block-1)*16/256);
					
					// colour (rgb)
					var light = 1.0;
					var side1 = false, side2 = false, corner = false;
					
					side1 = !isExposed(x + (blockStructure[v*3+0]==1?1:-1), y+(blockStructure[v*3+1]==1?1:-1), z);
					side2 = !isExposed(x, y+(blockStructure[v*3+1]==1?1:-1), z+(blockStructure[v*3+2]==1?1:-1));
					corner = !isExposed(x + (blockStructure[v*3+0]==1?1:-1), y+(blockStructure[v*3+1]==1?1:-1), z+(blockStructure[v*3+2]==1?1:-1));
					
					light = (3 - ((side1?1:0)+(side2?1:0)+(corner?1:0)))/3;
					light = .5 + .5 * light;
					
					ao.push(light);
					
					chunk.vertexData.push(light);
					chunk.vertexData.push(light);
					chunk.vertexData.push(light);
				}
				
				// Register quad as two triangles through index buffer
				// Flip if AO is backwards
				if (ao[0] + ao[2] > ao[1] + ao[3]) {
					chunk.indexData.push(vertexIndex+0);
					chunk.indexData.push(vertexIndex+1);
					chunk.indexData.push(vertexIndex+2);
					
					chunk.indexData.push(vertexIndex+0);
					chunk.indexData.push(vertexIndex+2);
					chunk.indexData.push(vertexIndex+3);
				}else{
					chunk.indexData.push(vertexIndex+1);
					chunk.indexData.push(vertexIndex+2);
					chunk.indexData.push(vertexIndex+3);
					
					chunk.indexData.push(vertexIndex+1);
					chunk.indexData.push(vertexIndex+3);
					chunk.indexData.push(vertexIndex+0);
				}
				_facesProduced++;
				vertexIndex += 4;
			}
			blockIndex++;
		}

		var vertexByteSize = 8;
		// Load the generated vertex data into a buffer
		chunk.vertexBuffer = new VertexBuffer(Std.int(chunk.vertexData.length/vertexByteSize), structure, StaticUsage);
		var vertexBufferData = chunk.vertexBuffer.lock();
		for (i in 0...chunk.vertexData.length)
			vertexBufferData[i] = chunk.vertexData[i];
		chunk.vertexBuffer.unlock();
		
		// Load the generated index data into a buffer
		chunk.indexBuffer = new IndexBuffer(chunk.indexData.length, StaticUsage);
		var indexBufferData = chunk.indexBuffer.lock();
		for (i in 0...Std.int(chunk.indexData.length))
			indexBufferData[i] = chunk.indexData[i];
		chunk.indexBuffer.unlock();
	}
	
	function constructGeometry() {
		for (chunk in chunks.iterator()) {
			constructChunkGeometry(chunk);
		}
	}
	
	function calculateMVP() {
		var projection = FastMatrix4.perspectiveProjection(80*Math.PI/180, kha.Window.get(0).width / kha.Window.get(0).height, .1, 100);
		
		// Conversion from spherical to cartesian coordinates uses projection
		var lookVector = new FastVector3(
			Math.cos(camera.verticalAngle) * Math.sin(camera.horizontalAngle),
			Math.sin(camera.verticalAngle),
			Math.cos(camera.verticalAngle) * Math.cos(camera.horizontalAngle)
		);
		
		var view = FastMatrix4.lookAt(camera.position.fast(), camera.position.fast().add(lookVector), new FastVector3(0,1,0));
		var model = FastMatrix4.identity();
		
		mvp = FastMatrix4.identity();
		mvp = mvp.multmat(projection);
		mvp = mvp.multmat(view);
		mvp = mvp.multmat(model);
	}
	
	public function update() {
		calculateMVP();
		
		var cameraChunkX = Math.floor(camera.position.x/Chunk.chunkSize);
		var cameraChunkZ = Math.floor(camera.position.z/Chunk.chunkSize);
		
		
		var isNewChunks = false;

		var radius = 4;
		for (x in -radius...radius+1)
			for (y in 0...3)
				for (z in -radius...radius+1)
					if (getChunk(cameraChunkX+x,y,cameraChunkZ+z) == null) {
						isNewChunks = true;
						var newChunk = new Chunk(cameraChunkX+x,y,cameraChunkZ+z);
						registerChunk(newChunk);
					}
		
		for (chunk in chunks.iterator()) {
			if (Math.min(Math.abs(chunk.wx - cameraChunkX), Math.abs(chunk.wz - cameraChunkZ)) > radius) {
				chunk.destroyGeometry();
				chunks.remove('${chunk.wx},${chunk.wy},${chunk.wz}');
				chunk = null;
			}
		}
		// chunks.filter(function(c) return c.hasGeometry());
		
		if (isNewChunks) {
			constructGeometry();
		}
	}

	public function render(g:Graphics) {
		g.setPipeline(pipeline);
		
		g.setMatrix(mvpID, mvp);
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
}
