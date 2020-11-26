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
        structure.add("tangent",VertexData.Float3);
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
        viewMatrixID = pipeline.getConstantLocation("View");
    }
    public function renderLine(start:kha.math.Vector3, end:kha.math.Vector3, colour:kha.Color) {
        indices.push(Std.int(vertices.length/9)+0);
        indices.push(Std.int(vertices.length/9)+1);
        indices.push(Std.int(vertices.length/9)+2);
        indices.push(Std.int(vertices.length/9)+1);
        indices.push(Std.int(vertices.length/9)+2);
        indices.push(Std.int(vertices.length/9)+3);

        var viewVector = start.sub(camera.position);
        var tangent = end.sub(start).normalized().cross(viewVector.normalized()).normalized();
        vertices.push(start.x);
        vertices.push(start.y);
        vertices.push(start.z);
        vertices.push(tangent.x);
        vertices.push(tangent.y);
        vertices.push(tangent.z);
        vertices.push(colour.R);
        vertices.push(colour.G);
        vertices.push(colour.B);

        vertices.push(start.x);
        vertices.push(start.y);
        vertices.push(start.z);
        vertices.push(-tangent.x);
        vertices.push(-tangent.y);
        vertices.push(-tangent.z);
        vertices.push(colour.R);
        vertices.push(colour.G);
        vertices.push(colour.B);

        vertices.push(end.x);
        vertices.push(end.y);
        vertices.push(end.z);
        vertices.push(tangent.x);
        vertices.push(tangent.y);
        vertices.push(tangent.z);
        vertices.push(colour.R);
        vertices.push(colour.G);
        vertices.push(colour.B);

        vertices.push(end.x);
        vertices.push(end.y);
        vertices.push(end.z);
        vertices.push(-tangent.x);
        vertices.push(-tangent.y);
        vertices.push(-tangent.z);
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
        g.setMatrix(mvpID, camera.mvp);
        g.setMatrix(viewMatrixID, camera.view);
        g.setVertexBuffer(vertexBuffer);
        g.setIndexBuffer(indexBuffer);
        g.drawIndexedVertices();
    }
}