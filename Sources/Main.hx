package;

import kha.input.Keyboard;
import kha.math.Vector3;
import kha.input.Mouse;
import kha.Assets;
import kha.Framebuffer;
import kha.Scheduler;
import kha.System;

class Main {
	var scene:Scene;
	var camera:Camera;
	var player:Player;

	var zoom = 10;
	var down = false;

	var forwards = false;

	function new () {
		camera = new Camera();
		scene = new Scene(camera);
		player = new Player();
		Mouse.get().notify(function(b,x,y){down=true;Mouse.get().lock();}, function(b,x,y){down=false;Mouse.get().unlock();}, function(x,y,dx,dy){
			if (!down)
				return;
			camera.horizontalAngle -= dx/400;
			camera.verticalAngle -= dy/400;
		}, function(delta){
			zoom += delta;
		});

		Keyboard.get().notify(function down(key){
			if (key == W) {
				forwards = true;
			}
		}, function up(key){
			if (key == W) {
				forwards = false;
			}

		});
	}

	function update(): Void {
		// camera.position = new FastVector3(30*Math.cos(Scheduler.realTime()*.3),10,30*Math.sin(Scheduler.realTime()*.3));
		// camera.position = new Vector3(30*Math.cos(Scheduler.realTime()*.3),10,30*Math.sin(Scheduler.realTime()*.3));
		camera.position = player.position.add(new Vector3(0,1,0));
		// trace(camera.position);
		scene.update();
		if (player.position.y > 2) {
			player.position.y -= .1;
		}
		if (forwards) {
			player.position.z += Math.cos(camera.horizontalAngle) * 1/60 * 5;
			player.position.x += Math.sin(camera.horizontalAngle) * 1/60 * 5;
		}
	}

	function render(framebuffer: Framebuffer): Void {
		var g4 = framebuffer.g4;
		g4.begin();
		g4.clear(kha.Color.fromBytes(49, 61, 82),1.0);
		scene.render(g4);
		g4.end();
	}

	public static function main() {
		System.start({title: "Kha", width: 800, height: 600}, function (_) {
			Assets.loadEverything(function () {
				var main = new Main();
				Scheduler.addTimeTask(function () { main.update(); }, 0, 1 / 60);
				System.notifyOnFrames(function (framebuffers) { main.render(framebuffers[0]); });
			});
		});
	}
}
