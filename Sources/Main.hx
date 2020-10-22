package;

import kha.math.Vector2;
import kha.math.FastMatrix3;
import kha.math.Vector3;
import kha.Assets;
import kha.Framebuffer;
import kha.Scheduler;
import kha.System;

class Main {
	var scene:Scene;
	var camera:Camera;
	var player:Player;
	var input:Input;

	var zoom = 10;
	var down = false;


	function new () {
		camera = new Camera();
		input = new Input(camera);
		scene = new Scene(camera);
		player = new Player();
	}

	function update(): Void {
		camera.position = player.position.add(new Vector3(0,1,0));
		scene.update();
		if (player.position.y > 2) {
			player.position.y -= .1;
		}

		var localMovementVector = new Vector2(0,0);
		if (input.forwards) {
			localMovementVector.x += 1;
		}
		if (input.left) {
			localMovementVector.y -= 1;
		}
		if (input.right) {
			localMovementVector.y += 1;
		}
		if (input.backwards) {
			localMovementVector.x -= 1;
		}
		var movement = FastMatrix3.rotation(Math.PI/2-camera.horizontalAngle).multvec(localMovementVector.fast()).normalized().mult(1/60*5);
		player.position.x += movement.x;
		player.position.z += movement.y;
	}

	function render(framebuffer: Framebuffer): Void {
		var g4 = framebuffer.g4;
		g4.begin();
		g4.clear(kha.Color.fromBytes(49, 61, 82),1.0);
		scene.render(g4);
		g4.end();
	}

	public static function main() {
		System.start({title: "Blocks", width: 800, height: 600}, function (_) {
			Assets.loadEverything(function () {
				var main = new Main();
				Scheduler.addTimeTask(function () { main.update(); }, 0, 1 / 60);
				System.notifyOnFrames(function (framebuffers) { main.render(framebuffers[0]); });
			});
		});
	}
}
