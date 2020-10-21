package ;

import kha.Shaders;
import kha.graphics5_.VertexData;
import kha.graphics4.VertexStructure;
import kha.graphics4.PipelineState;
import kha.graphics4.IndexBuffer;
import kha.graphics4.VertexBuffer;
import kha.graphics4.Graphics;

class Scene {
	var blocks:Array<Block> = [];
	var vertices:Array<Float> = [];
	var indices:Array<Int> = [];

	var vertexBuffer:VertexBuffer;
	var indexBuffer:IndexBuffer;
	var pipeline:PipelineState;

	var blockStructure = [
		0, 0, 0,
		1, 0, 0,
		1, 1, 0,
		0, 1, 0,
		0, 0, 1,
		1, 0, 1,
		1, 1, 1,
		0, 1, 1
	];
	var blockIndices = [
		0, 1, 3,
		1, 3, 2,
		0, 1, 5,
		5, 0, 4,
		0, 3, 7,
		0, 4, 7,
		1, 5, 6,
		1, 2, 6,
		2, 3, 7,
		2, 6, 7,
		5, 6, 4,
		6, 4, 7
	];

	public function new() {
		blocks.push(new Block());
		constructGeometry();
	}

	function constructGeometry() {
		// Vertex structure
		var structure = new VertexStructure();
		structure.add("pos", VertexData.Float3);

		// Pipeline
		pipeline = new PipelineState();
		pipeline.inputLayout = [structure];
		pipeline.fragmentShader = Shaders.block_frag;
		pipeline.vertexShader = Shaders.block_vert;
		pipeline.compile();

		// Vertex Data
		vertexBuffer = new VertexBuffer(blocks.length * 8, structure, StaticUsage);
		var vertexBufferData = vertexBuffer.lock();
		var offset = 0;
		for (block in blocks) {
			for (v in 0...blockStructure.length) {
				vertexBufferData[offset++] = blockStructure[v];
			}
		}
		vertexBuffer.unlock();

		// Index Data
		indexBuffer = new IndexBuffer(blocks.length * blockIndices.length, StaticUsage);
		var indexBufferData = indexBuffer.lock();
		var offset = 0;
		for (block in blocks) {
			for (i in 0...blockIndices.length) {
				indexBufferData[offset++] = blockIndices[i];
			}
		}
		indexBuffer.unlock();
	}

	public function update() {

	}
	public function render(g:Graphics) {
		g.setPipeline(pipeline);

		g.setVertexBuffer(vertexBuffer);
		g.setIndexBuffer(indexBuffer);

		g.drawIndexedVertices();
	}
}
