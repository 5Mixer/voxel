package ;

import kha.math.Vector3;
import kha.arrays.Uint32Array;
import kha.arrays.Float32Array;
import kha.graphics4.Graphics;
import kha.graphics4.VertexStructure;
import kha.graphics4.PipelineState;
import kha.graphics4.IndexBuffer;
import kha.graphics4.VertexBuffer;
import kha.graphics4.VertexData;
import kha.graphics4.ConstantLocation;
import kha.graphics4.CompareMode;
import kha.Shaders;

class LineRenderer {
	var structure:VertexStructure;
	var vertexBuffer:VertexBuffer;
	var indexBuffer:IndexBuffer;
	var pipeline:PipelineState;
	
    var mvpID:ConstantLocation;
    var viewMatrixID:ConstantLocation;

    var camera:Camera;

    var vertices = [];
    var indices = [];

    public function new(camera:Camera) {
        setupPipeline();
        this.camera = camera;
    }
	function setupPipeline() {
		// Vertex structure
		structure = new VertexStructure();
        structure.add("pos", VertexData.Float3);
        structure.add("normal",VertexData.Float3);
		structure.add("colour", VertexData.Float3);
		
		// Pipeline
		pipeline = new PipelineState();
		pipeline.inputLayout = [structure];
		pipeline.fragmentShader = Shaders.line_frag;
		pipeline.vertexShader = Shaders.line_vert;
		
		pipeline.depthWrite = true;
		pipeline.depthMode = CompareMode.Less;
		
		pipeline.colorAttachmentCount = 1;
		pipeline.colorAttachments[0] = kha.graphics4.TextureFormat.RGBA32;
		pipeline.depthStencilAttachment = kha.graphics4.DepthStencilFormat.Depth16;
		
		pipeline.compile();
		
		// Graphics variables
        mvpID = pipeline.getConstantLocation("MVP");
    }
    public function renderLine(start:kha.math.Vector3, end:kha.math.Vector3, colour:kha.Color) {
        indices.push(Std.int(vertices.length/9)+0);
        indices.push(Std.int(vertices.length/9)+1);
        indices.push(Std.int(vertices.length/9)+2);
        indices.push(Std.int(vertices.length/9)+1);
        indices.push(Std.int(vertices.length/9)+2);
        indices.push(Std.int(vertices.length/9)+3);

        var viewVector = start.sub(camera.position);
        var normal = end.sub(start).normalized().cross(viewVector.normalized()).normalized();
        vertices.push(start.x);
        vertices.push(start.y);
        vertices.push(start.z);
        vertices.push(normal.x);
        vertices.push(normal.y);
        vertices.push(normal.z);
        vertices.push(colour.R);
        vertices.push(colour.G);
        vertices.push(colour.B);

        vertices.push(start.x);
        vertices.push(start.y);
        vertices.push(start.z);
        vertices.push(-normal.x);
        vertices.push(-normal.y);
        vertices.push(-normal.z);
        vertices.push(colour.R);
        vertices.push(colour.G);
        vertices.push(colour.B);

        vertices.push(end.x);
        vertices.push(end.y);
        vertices.push(end.z);
        vertices.push(normal.x);
        vertices.push(normal.y);
        vertices.push(normal.z);
        vertices.push(colour.R);
        vertices.push(colour.G);
        vertices.push(colour.B);

        vertices.push(end.x);
        vertices.push(end.y);
        vertices.push(end.z);
        vertices.push(-normal.x);
        vertices.push(-normal.y);
        vertices.push(-normal.z);
        vertices.push(colour.R);
        vertices.push(colour.G);
        vertices.push(colour.B);
    }

    public function start(g:Graphics) {
        vertices = [];
        indices = [];
    }
    
    public function end(g:Graphics) {
        vertexBuffer = new VertexBuffer(Std.int(vertices.length/9), structure, StaticUsage);
        indexBuffer = new IndexBuffer(indices.length, StaticUsage);

        var vertexBufferData = vertexBuffer.lock();
		for (i in 0...vertices.length)
			vertexBufferData[i] = vertices[i];
		vertexBuffer.unlock();

        var indexBufferData = indexBuffer.lock();
		for (i in 0...Std.int(indices.length))
            indexBufferData[i] = indices[i];
        indexBuffer.unlock();

        g.setPipeline(pipeline);
        g.setMatrix(mvpID, camera.getMVP());
        g.setVertexBuffer(vertexBuffer);
        g.setIndexBuffer(indexBuffer);
        g.drawIndexedVertices();
    }

	public function renderAABB(aabb:AABB, col = kha.Color.Blue) {
		var min = aabb.min;
		var max = aabb.max;
		// Bottom of AABB
		renderLine(new Vector3(min.x, min.y, min.z), new Vector3(max.x, min.y, min.z), col);
		renderLine(new Vector3(min.x, min.y, min.z), new Vector3(min.x, min.y, max.z), col);
		renderLine(new Vector3(max.x, min.y, max.z), new Vector3(min.x, min.y, max.z), col);
		renderLine(new Vector3(max.x, min.y, max.z), new Vector3(max.x, min.y, min.z), col);
		// Sides of AABB
		renderLine(new Vector3(min.x, min.y, min.z), new Vector3(min.x, max.y, min.z), col);
		renderLine(new Vector3(max.x, min.y, min.z), new Vector3(max.x, max.y, min.z), col);
		renderLine(new Vector3(min.x, min.y, max.z), new Vector3(min.x, max.y, max.z), col);
		renderLine(new Vector3(max.x, min.y, max.z), new Vector3(max.x, max.y, max.z), col);
		// Top of AABB
		renderLine(new Vector3(min.x, max.y, min.z), new Vector3(max.x, max.y, min.z), col);
		renderLine(new Vector3(min.x, max.y, min.z), new Vector3(min.x, max.y, max.z), col);
		renderLine(new Vector3(max.x, max.y, max.z), new Vector3(min.x, max.y, max.z), col);
		renderLine(new Vector3(max.x, max.y, max.z), new Vector3(max.x, max.y, min.z), col);
	}
}