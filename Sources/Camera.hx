package ;

import kha.math.Vector3;

class Camera {
    public var position:Vector3;
    public var horizontalAngle:Float=0;
    public var verticalAngle:Float=0;
    public function new() {
        position = new Vector3();
    }
}