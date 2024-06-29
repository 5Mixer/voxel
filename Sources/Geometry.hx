package ;

import kha.graphics4.VertexBuffer;
import kha.graphics4.IndexBuffer;

class Geometry {
    public var indexBuffer:IndexBuffer;
    public var vertexBuffer:VertexBuffer;
    
    public function new(indexBuffer:IndexBuffer, vertexBuffer:VertexBuffer) {
        this.indexBuffer = indexBuffer;
        this.vertexBuffer = vertexBuffer;
    }
}