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

		kha.Assets.images.sprites.generateMipmaps(3);

		for (x in 0...chunkSize)
			for (y in 0...chunkSize)
				for (z in 0...chunkSize) {
					blocks.push(0);
				}
		
		for (x in 0...chunkSize)
			for (z in 0...chunkSize)
				for (y in 0...20+Math.ceil(5*Math.sin(x/10)+5*Math.cos(z/10)))
					setBlock(x,y,z,Math.random()>.5?1:2);

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
				// For faces that face anything other than air, skip
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

				// Register quad as two triangles through index buffer
				generatedIndexData.push(vertexIndex);
				generatedIndexData.push(vertexIndex+1);
				generatedIndexData.push(vertexIndex+2);
				generatedIndexData.push(vertexIndex);
				generatedIndexData.push(vertexIndex+2);
				generatedIndexData.push(vertexIndex+3);

				for (triangleVertex in 0...4) {
					var v = face*4 + triangleVertex; // v is the [0-24) vertices of the quad

					// position (xyz)
					var position = new Vector3(blockStructure[v*3+0]+x, blockStructure[v*3+1]+y, blockStructure[v*3+2]+z);
					generatedVertexData.push(position.x);
					generatedVertexData.push(position.y);
					generatedVertexData.push(position.z);

					// texture (uv)
					generatedVertexData.push(uv[v*2]  *16/256);
					generatedVertexData.push((uv[v*2+1]+block-1)*16/256);


					// colour (rgb)
					var light = 1.0;
						var side1 = false, side2 = false, corner = false;
						// if (triangleVertex == 0) {
						// 	side1 =  !isAir(x+1, y+1, z);
						// 	side2 =  !isAir(x,   y+1, z-1);
						// 	corner = !isAir(x+1, y+1, z-1);
						// }
						// if (triangleVertex == 1) {
						// 	side1 =  !isAir(x-1, y+1, z);
						// 	side2 =  !isAir(x,   y+1, z-1);
						// 	corner = !isAir(x-1, y+1, z-1);
						// }
						// if (triangleVertex == 2) {
						// 	side1 =  !isAir(x-1, y+1, z);
						// 	side2 =  !isAir(x,   y+1, z+1);
						// 	corner = !isAir(x-1, y+1, z+1);
						// }
						// if (triangleVertex == 3) {
						// 	side1 =  !isAir(x+1, y+1, z);
						// 	side2 =  !isAir(x,   y+1, z+1);
						// 	corner = !isAir(x+1, y+1, z+1);
						// }
						side1 = !isAir(x + (blockStructure[v*3+0]==1?1:-1), y+(blockStructure[v*3+1]==1?1:-1), z);
						side2 = !isAir(x, y+(blockStructure[v*3+1]==1?1:-1), z+(blockStructure[v*3+2]==1?1:-1));
						corner = !isAir(x + (blockStructure[v*3+0]==1?1:-1), y+(blockStructure[v*3+1]==1?1:-1), z+(blockStructure[v*3+2]==1?1:-1));

						light = (3 - ((side1?1:0)+(side2?1:0)+(corner?1:0)))/3;

						// light = .5 + .5*light;

					generatedVertexData.push(light);
					generatedVertexData.push(light);
					generatedVertexData.push(light);

					vertexIndex++;
				}
			}
			blockIndex++;
		}

		var vertexByteSize = 8;
		// Load the generated vertex data into a buffer
		vertexBuffer = new VertexBuffer(Std.int(generatedVertexData.length/vertexByteSize), structure, StaticUsage);
		var vertexBufferData = vertexBuffer.lock();
		for (i in 0...generatedVertexData.length)
			vertexBufferData[i] = generatedVertexData[i];
		vertexBuffer.unlock();

		// Load the generated index data into a buffer
		indexBuffer = new IndexBuffer(Std.int(generatedIndexData.length), StaticUsage);
		var indexBufferData = indexBuffer.lock();
		for (i in 0...Std.int(generatedIndexData.length))
			indexBufferData[i] = generatedIndexData[i];
		indexBuffer.unlock();
	}

	function calculateMVP() {
		var projection = FastMatrix4.perspectiveProjection(80*Math.PI/180, kha.Window.get(0).width / kha.Window.get(0).height, .1, 100);

		// Conversion from spherical to cartesian coordinates uses projection
		var lookVector = new FastVector3(
			Math.cos(camera.verticalAngle) * Math.sin(camera.horizontalAngle),
			Math.sin(camera.verticalAngle),
			Math.cos(camera.verticalAngle) * Math.cos(camera.horizontalAngle)
		);

		var view = FastMatrix4.lookAt(camera.position.fast(), camera.position.fast().add(lookVector), new FastVector3(0,1.6,0));
		var model = FastMatrix4.identity();

		mvp = FastMatrix4.identity();
		mvp = mvp.multmat(projection);
		mvp = mvp.multmat(view);
		mvp = mvp.multmat(model);
	}

	public function update() {
		calculateMVP();
		constructGeometry();
	}
	public function render(g:Graphics) {
		g.setPipeline(pipeline);

		g.setMatrix(mvpID, mvp);
		g.setTexture(textureID, kha.Assets.images.sprites);
		g.setTextureParameters(textureID, Clamp, Clamp, TextureFilter.PointFilter, TextureFilter.PointFilter, MipMapFilter.LinearMipFilter);
		

		g.setVertexBuffer(vertexBuffer);
		g.setIndexBuffer(indexBuffer);

		g.drawIndexedVertices();
	}
}
