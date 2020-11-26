package ;

import kha.math.Vector3;
import kha.math.FastVector3;
import kha.math.FastMatrix4;

class Camera {
    public var position:Vector3;
    public var horizontalAngle:Float=Math.PI; // Start facing toward front, by pointing back
    public var verticalAngle:Float=0;
    public var mvp:FastMatrix4;
    public var projection:FastMatrix4;
    public var view:FastMatrix4;

    public function new() {
        position = new Vector3();
    }
    public function getLookVector() {
		// Conversion from spherical to cartesian coordinates uses projection
		return new Vector3(
			Math.cos(verticalAngle) * Math.sin(horizontalAngle),
			Math.sin(verticalAngle),
			Math.cos(verticalAngle) * Math.cos(horizontalAngle)
		);
    }
	
	public function recalculateMVP() {
		projection = FastMatrix4.perspectiveProjection(80*Math.PI/180, kha.Window.get(0).width / kha.Window.get(0).height, .15, 100);
		view = FastMatrix4.lookAt(position.fast(), position.add(getLookVector()).fast(), new FastVector3(0,1,0));
		// var model = FastMatrix4.identity();
		
		mvp = FastMatrix4.identity();
		mvp = mvp.multmat(projection);
		mvp = mvp.multmat(view);
		// mvp = mvp.multmat(model);
	}
}