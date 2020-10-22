package ;

import kha.math.Vector3;

class Player {
    public var position:Vector3;
    public var velocity:Vector3;
    public var size:Vector3;
    public function new() {
        position = new Vector3(0,4,0);
        velocity = new Vector3(0,0,0);
        size = new Vector3(.8,1.6,.8); // Camera positioned at top middle of bounds
    }
    public function getAABB() {
        return new AABB(position.sub(new Vector3(size.x/2,0,size.z/2)), position.add(new Vector3(size.x/2,size.y,size.z/2)));
    }
    public function update() {
        position = position.add(velocity);
    }
}