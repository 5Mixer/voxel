package;

import kha.Window;
import kha.math.Vector2;
import kha.math.FastVector4;
import kha.math.Vector3;
import kha.math.FastVector3;
import kha.math.FastMatrix4;

class Camera {
	public var position(default, set):Vector3;
	public var horizontalAngle(default, set):Float = Math.PI; // Start facing toward front, by pointing back
	public var verticalAngle(default, set):Float = 0;
	public var projection:FastMatrix4;
	public var view:FastMatrix4;
	public var fov = 80 * Math.PI / 180;
	public var realFov = 80 * Math.PI / 180;

	public var mvpDirty = true;

	var mvp:FastMatrix4;

	var aspectRatio:Float = 1;

	public function new() {
		position = new Vector3();
		kha.Window.get(0).notifyOnResize(function(width, height) {
			aspectRatio = width / height;
			mvpDirty = true;
		});
		aspectRatio = kha.Window.get(0).width / kha.Window.get(0).height;
	}

	public function getLookVector() {
		// Conversion from spherical to cartesian coordinates uses projection
		return new Vector3(Math.cos(verticalAngle) * Math.sin(horizontalAngle), Math.sin(verticalAngle), Math.cos(verticalAngle) * Math.cos(horizontalAngle));
	}

	public function getScreenPosition(vec:Vector3) {
		var transformed = getMVP().multvec(new FastVector4(vec.x, vec.y, vec.z));
		if (transformed.z < 0) return null;
		return new Vector2(
			((transformed.x / transformed.w) + 1) / 2 * Window.get(0).width,
			(-(transformed.y / transformed.w) + 1) / 2 * Window.get(0).height,
		);
	}

	public function getMVP() {
		if (!mvpDirty)
			return mvp;

		realFov = (realFov + fov) / 2;
		projection = FastMatrix4.perspectiveProjection(realFov, aspectRatio, .05, 160);
		view = FastMatrix4.lookAt(position.fast(), position.add(getLookVector()).fast(), new FastVector3(0, 1, 0));
		mvp = projection.multmat(view);

		return mvp;
	}

	function set_position(newPosition) {
		mvpDirty = true;
		return position = newPosition;
	}

	function set_horizontalAngle(newAngle) {
		mvpDirty = true;
		return horizontalAngle = newAngle;
	}

	function set_verticalAngle(newAngle) {
		mvpDirty = true;
		return verticalAngle = newAngle;
	}
}
