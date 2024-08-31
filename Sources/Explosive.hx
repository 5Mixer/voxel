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
        return new AABB(position, position.add(size));
    }

    public function update(scene:Scene) {
        moveAndSlide(scene);
    }

    function collides(scene:Scene) {
        var aabb = getAABB();
        for (x in Math.floor(aabb.min.x)...Math.ceil(aabb.max.x))
			for (y in Math.floor(aabb.min.y)...Math.ceil(aabb.max.y))
				for (z in Math.floor(aabb.min.z)...Math.ceil(aabb.max.z))
					if (!scene.isAir(x, y, z))
                        return true;
		return false;	
    }

    public function moveAndSlide(scene:Scene) {
        // y movement and collision resolution
		position.y += velocity.y;
		var shouldMoveY = !collides(scene);
		if (!shouldMoveY) {
			if (velocity.y > 0) {
				position.y = Math.ceil(position.y - velocity.y);
			} else {
				position.y = Math.floor(position.y - velocity.y);
			}
            velocity.y = 0;
            velocity.x *= .9;
            velocity.z *= .9;
		} else {
			velocity.y -= .01;
		}

		// x movement and collision resolution
		position.x += velocity.x;
		var shouldMoveX = !collides(scene);
		if (!shouldMoveX) {
            if (velocity.x > 0) {
                position.x = Math.ceil(position.x - velocity.x);
            } else {
                position.x = Math.floor(position.x - velocity.x);
            }
            velocity.x = 0;
		}

		// z movement and collision resolution
		position.z += velocity.z;
		var shouldMoveZ = !collides(scene);
		if (!shouldMoveZ) {
            if (velocity.z > 0) {
                position.z = Math.ceil(position.z - velocity.z);
            } else {
                position.z = Math.floor(position.z - velocity.z);
            }
            velocity.z = 0;
		}
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