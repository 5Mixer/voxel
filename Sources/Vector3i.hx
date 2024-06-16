package ;

class Vector3i {
    public var x:Int;
    public var y:Int;
    public var z:Int;

    public function new(x:Int, y:Int, z:Int) {
        this.x = x;
        this.y = y;
        this.z = z;
    }

    public function equals(other:Vector3i) {
        return this.x == other.x && this.y == other.y && this.z == other.z;
    }

    public function copy(other:Vector3i) {
        this.x = other.x;
        this.y = other.y;
        this.z = other.z;
    }

    public function lengthSquared() {
        return x * x + y * y + z * z;
    }
}