package ;

import kha.math.Vector3;

class Camera {
    public var position:Vector3;
    public var lookAt:Vector3;
    public function new() {
        position = new Vector3();
        lookAt = new Vector3(50,50,50);
    }
}