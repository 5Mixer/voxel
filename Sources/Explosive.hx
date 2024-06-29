package ;

import kha.graphics4.VertexStructure;
import kha.graphics4.IndexBuffer;
import kha.graphics5_.Usage;
import kha.graphics4.VertexBuffer;
import kha.math.Vector3;

class Explosive {
    public var position:Vector3;
    public var velocity = new Vector3();
    public var size = new Vector3(1, 1, 1);
    public var alive = true;

    public function new() {

    }

    public function getAABB() {
        return new AABB(position.sub(new Vector3(size.x/2,0,size.z/2)), position.add(new Vector3(size.x/2,size.y,size.z/2)));
    }

    public function update() {
        position.x += velocity.x;
        position.y += velocity.y;
        position.z += velocity.z;
        velocity.y -= 0.02;
        velocity.x *= .9999;
        velocity.z *= .9999;
    }
    

    public function render() {

    }

    public function getGeometry(entityRenderer:EntityRenderer) {
        if (position == null) return null;

        var vertexBuffer = new VertexBuffer(24, entityRenderer.structure, Usage.DynamicUsage);
        var indexBuffer = new IndexBuffer(36, Usage.DynamicUsage);
        var vertexBufferData = vertexBuffer.lock();
        var indexBufferData = indexBuffer.lock();

        for (vertexIndex in 0...24) {
            vertexBufferData[vertexIndex*6+0] = CubeGeometry.vertices[vertexIndex*3+0] + position.x;
            vertexBufferData[vertexIndex*6+1] = CubeGeometry.vertices[vertexIndex*3+1] + position.y;
            vertexBufferData[vertexIndex*6+2] = CubeGeometry.vertices[vertexIndex*3+2] + position.z;
            vertexBufferData[vertexIndex*6+3] = (CubeGeometry.uv[vertexIndex*2+0] + 6) / 16;
            vertexBufferData[vertexIndex*6+4] = (CubeGeometry.uv[vertexIndex*2+1] + 0) / 16;
            vertexBufferData[vertexIndex*6+5] = 1.0;
        }

        var indexDataIndex = 0;
        for (face in 0...6) {
            indexBufferData.set(indexDataIndex++, (face*4 + 0));
            indexBufferData.set(indexDataIndex++, (face*4 + 1));
            indexBufferData.set(indexDataIndex++, (face*4 + 2));

            indexBufferData.set(indexDataIndex++, (face*4 + 0));
            indexBufferData.set(indexDataIndex++, (face*4 + 2));
            indexBufferData.set(indexDataIndex++, (face*4 + 3));
        }

        vertexBuffer.unlock();
        indexBuffer.unlock();

        return new Geometry(indexBuffer, vertexBuffer);
    }
}