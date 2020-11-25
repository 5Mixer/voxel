package ;

import kha.math.Vector3;

class AABB {
    public var min:Vector3;
    public var max:Vector3;
    public function new(min:Vector3,max:Vector3) {
        this.min = min;
        this.max = max;
    }
    public function doesCollide(other:AABB) {
        return (min.x <= other.max.x && max.x >= other.min.x) &&
               (min.y <= other.max.y && max.y >= other.min.y) &&
               (min.z <= other.max.z && max.z >= other.min.z);
    }
}