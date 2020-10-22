package ;

import kha.math.Vector3;
import kha.graphics5_.MipMapFilter;
import kha.graphics5_.TextureFilter;
import kha.graphics5_.TextureAddressing;
import kha.Scheduler;
import kha.graphics4.TextureUnit;
import kha.graphics5_.CompareMode;
import kha.math.FastVector3;
import kha.math.FastMatrix4;
import kha.graphics4.ConstantLocation;
import kha.math.FastMatrix3;
import kha.Shaders;
import kha.graphics5_.VertexData;
import kha.graphics4.VertexStructure;
import kha.graphics4.PipelineState;
import kha.graphics4.IndexBuffer;
import kha.graphics4.VertexBuffer;
import kha.graphics4.Graphics;

class Scene {
	var blockRegistry = [];
	var blocks:Array<Int> = [];
	var indices:Array<Int> = [];

	var vertexBuffer:VertexBuffer;
	var indexBuffer:IndexBuffer;
	var pipeline:PipelineState;
	var camera:Camera;

	var blockStructure = [
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

		1, 1, 0,
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
	var blockIndices = [
		0, 1, 2,
		0, 2, 3,

		4, 5, 6,
		4, 6, 7,

		8, 9, 10,
		8,10, 11,

		12, 13, 14,
		12, 14, 15,

		16, 17, 18,
		16, 18, 19,

		20, 21, 22,
		20, 22, 23

	];
	var uv = [
		1, 1,
		0, 1,
		0, 0,
		1, 0,

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

		5, 1,
		5, 0,
		6, 0,
		6, 1
	];

	var mvp:FastMatrix4;
	var mvpID:ConstantLocation;
	var textureID:TextureUnit;

	static inline var chunkSize = 100;
	var min = new Vector3(0,0,0);
	var max = new Vector3(chunkSize-1,chunkSize-1,chunkSize-1);

	public function new(camera:Camera) {
		this.camera = camera;

		for (x in 0...chunkSize)
			for (y in 0...chunkSize)
				for (z in 0...chunkSize) {
					blocks.push(0);
					// blocks.push(Math.sqrt(Math.pow(x-50,2)+Math.pow(y-50,2)+Math.pow(z-50,2)) < 50 ? 1 : 0);
				}
		
		for (x in 0...chunkSize)
			for (z in 0...chunkSize)
				setBlock(x,0,z,1);

		constructGeometry();
	}

	inline public function getBlock(x, y, z) {
		return blocks[x*(chunkSize*chunkSize) + y*chunkSize + z];
	}
	function setBlock(x,y,z,b){
		blocks[x*(chunkSize*chunkSize) + y*chunkSize + z] = b;
	}
	inline public function isAir(x:Int, y:Int, z:Int) {
		if (x<min.x||y<min.y||z<min.z||x>max.x||y>max.y||z>max.z)
			return true;
		return getBlock(x,y,z) == 0;
	}

	function constructGeometry() {
		// Vertex structure
		var structure = new VertexStructure();
		structure.add("pos", VertexData.Float3);
		structure.add("uv", VertexData.Float2);

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
		calculateMVP();
		textureID = pipeline.getTextureUnit("textureSampler");

		// Vertex Data
		var generatedVertexData:Array<Float> = [];
		var generatedIndexData:Array<Int> = [];
		var blockIndex = 0;
		var vertexIndex = 0;
		for (block in blocks) {
			if (block == 0){
				blockIndex++;
				continue;
			}

			var x = Math.floor(blockIndex/(chunkSize*chunkSize));
			var y = Math.floor(blockIndex/chunkSize)%chunkSize;
			var z = blockIndex%chunkSize;

			for (face in 0...6) {
				if (face == 0 && !isAir(x,y,z-1)) // Right
					continue;

				if (face == 1 && !isAir(x,y,z+1)) // Left
					continue;

				if (face == 2 && !isAir(x+1,y,z)) // Front (facing camera)
					continue;

				if (face == 3 && !isAir(x,y+1,z)) // Top
					continue;

				if (face == 4 && !isAir(x,y-1,z)) //Under/bottom
					continue;
				
				if (face == 5 && !isAir(x-1,y,z)) //back
					continue;

				generatedIndexData.push(vertexIndex);
				generatedIndexData.push(vertexIndex+1);
				generatedIndexData.push(vertexIndex+2);
				generatedIndexData.push(vertexIndex);
				generatedIndexData.push(vertexIndex+2);
				generatedIndexData.push(vertexIndex+3);
				for (triangleVertex in 0...4) {
					var v = face*4 + triangleVertex;
					

					generatedVertexData.push(blockStructure[v*3+0]+x);
					generatedVertexData.push(blockStructure[v*3+1]+y);
					generatedVertexData.push(blockStructure[v*3+2]+z);

					generatedVertexData.push(uv[v*2]  *16/256);
					generatedVertexData.push(uv[v*2+1]*16/256);

					vertexIndex++;
				}
			}
			blockIndex++;
		}
		vertexBuffer = new VertexBuffer(Std.int(generatedVertexData.length/5), structure, StaticUsage);
		var vertexBufferData = vertexBuffer.lock();
		for (i in 0...generatedVertexData.length)
			vertexBufferData[i] = generatedVertexData[i];
		vertexBuffer.unlock();

		// Index Data
		indexBuffer = new IndexBuffer(Std.int(generatedIndexData.length), StaticUsage);
		var indexBufferData = indexBuffer.lock();
		for (i in 0...Std.int(generatedIndexData.length))
			indexBufferData[i] = generatedIndexData[i];
		indexBuffer.unlock();

		trace('Generated geometry. VB size: ${vertexBuffer.count()} IB size: ${indexBuffer.count()}');
	}

	function calculateMVP() {
		var projection = FastMatrix4.perspectiveProjection(45, kha.Window.get(0).width / kha.Window.get(0).height, .1, 100);

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
	}
	public function render(g:Graphics) {
		g.setPipeline(pipeline);

		g.setMatrix(mvpID, mvp);
		g.setTexture(textureID, kha.Assets.images.sprites);
		g.setTextureParameters(textureID, Clamp, Clamp, TextureFilter.PointFilter, TextureFilter.PointFilter, MipMapFilter.NoMipFilter);

		g.setVertexBuffer(vertexBuffer);
		g.setIndexBuffer(indexBuffer);

		g.drawIndexedVertices();
	}
}
