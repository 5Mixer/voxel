package ;

import kha.math.Matrix3;
import kha.math.Vector2;
import kha.math.Vector3;

class Player {
    public var position:Vector3;
    public var velocity:Vector3;
    public var size:Vector3;
	public var sprinting = false;
    var headHeight = 1.4;
	var jumps = 0;
	var maxJumps = 2;
    var onFloor = false;
    var walkSpeed = 1 / 12;
    var sprintSpeed = 1 / 6;

    public function new() {
        position = new Vector3(0,8,0); // Bottom middle of AABB (ie. on the ground)
        velocity = new Vector3(0,0,0);
        size = new Vector3(.8,1.5,.8); // Camera positioned at middle of bounds, headHeight high
    }

    public function getHeadPosition() {
        return position.add(new Vector3(0, headHeight, 0));
    }

    public function getAABB() {
        return new AABB(position.sub(new Vector3(size.x/2,0,size.z/2)), position.add(new Vector3(size.x/2,size.y,size.z/2)));
    }

    public function update(input:Input, scene:Scene, camera:Camera) {
        var localMovementVector = new Vector2(0, 0);
		if (input.forwards) localMovementVector.x += 1; else sprinting = false;
		if (input.left) localMovementVector.y -= 1;
		if (input.right) localMovementVector.y += 1;
		if (input.backwards) localMovementVector.x -= 1;
		
		var movement = Matrix3.rotation(Math.PI / 2 - camera.horizontalAngle)
			.multvec(localMovementVector)
			.normalized()
			.mult(sprinting ? sprintSpeed : walkSpeed);

		var onFloor = moveAndSlide(movement, scene);
        if (onFloor && input.space) jump();
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

    public function moveAndSlide(movement:Vector2, scene:Scene) {
        var onFloor = false;
        // y movement and collision resolution
		position.y += velocity.y;
		var shouldMoveY = !collides(scene);
		if (!shouldMoveY) {
            var aabb = getAABB();
			if (velocity.y > 0) {
				position.y = Math.floor(aabb.max.y + velocity.y) - size.y;
				velocity.y = 0;
			} else {
				position.y = Math.ceil(aabb.min.y + velocity.y);
				jumps = 0;
				velocity.y = 0;
                onFloor = true;
			}            
		} else {
			velocity.y -= .01;
		}

		// x movement and collision resolution
		position.x += movement.x;
		var shouldMoveX = !collides(scene);
		if (!shouldMoveX) {
			position.x -= movement.x;
			sprinting = false;
		}

		// z movement and collision resolution
		position.z += movement.y;
		var shouldMoveZ = !collides(scene);
		if (!shouldMoveZ) {
			position.z -= movement.y;
			sprinting = false;
		}

        return onFloor;
    }

    public function jump() {
        if (jumps < maxJumps) {
            velocity.y = .17;
            jumps++;
        }
    }
}