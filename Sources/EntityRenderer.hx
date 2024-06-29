package ;

import kha.math.Vector3;
import kha.graphics5_.VertexStructure;
import kha.graphics4.*;
import kha.Shaders;

class EntityRenderer {
    public var structure:VertexStructure;
	var vertexBuffer:VertexBuffer;
	var indexBuffer:IndexBuffer;
	var pipeline:PipelineState;

	var mvpID:ConstantLocation;
	var textureID:TextureUnit;

	var camera:Camera;
    var explosives:Array<Explosive>;

    public function new (camera:Camera, explosives:Array<Explosive>) {
        this.camera = camera;
        this.explosives = explosives;
        setupPipeline();
    }
 
	function setupPipeline() {
		// Vertex structure
		structure = new VertexStructure();
		structure.add("pos", VertexData.Float32_3X);
		structure.add("uv", VertexData.Float32_2X);
		structure.add("colour", VertexData.Float32_1X);

		// Pipeline
		pipeline = new PipelineState();
		pipeline.inputLayout = [structure];
		pipeline.fragmentShader = Shaders.entity_frag;
		pipeline.vertexShader = Shaders.entity_vert;

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

	public function render(g:Graphics) {
		g.setPipeline(pipeline);

		g.setMatrix(mvpID, camera.getMVP());
		g.setTexture(textureID, kha.Assets.images.sprites);
		g.setTextureParameters(textureID, Clamp, Clamp, TextureFilter.PointFilter, TextureFilter.PointFilter, MipMapFilter.NoMipFilter);

        for (explosive in explosives) {
            var geometry = explosive.getGeometry(this);
            if (geometry == null) continue;
            g.setVertexBuffer(geometry.vertexBuffer);
            g.setIndexBuffer(geometry.indexBuffer);
            g.drawIndexedVertices();
        }
    }
}