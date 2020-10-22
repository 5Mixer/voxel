package;

import kha.math.Vector3;
import kha.input.Mouse;
import kha.Assets;
import kha.Framebuffer;
import kha.Scheduler;
import kha.System;

class Main {
	var scene:Scene;
	var camera:Camera;
	var long = 0;
	var lat = 0;
	var zoom = 10;
	var down = false;
	function new () {
		camera = new Camera();
		scene = new Scene(camera);
		Mouse.get().notify(function(b,x,y){down=true;Mouse.get().lock();}, function(b,x,y){down=false;Mouse.get().unlock();}, function(x,y,dx,dy){
			if (!down)
				return;
			lat += dx;
			long += dy;
		}, function(delta){
			zoom += delta;
		});
	}

	function update(): Void {
		// camera.position = new FastVector3(30*Math.cos(Scheduler.realTime()*.3),10,30*Math.sin(Scheduler.realTime()*.3));
		// camera.position = new Vector3(30*Math.cos(Scheduler.realTime()*.3),10,30*Math.sin(Scheduler.realTime()*.3));
		camera.position.x = 5+zoom * Math.cos(lat/300);
		camera.position.y = 5+zoom * long/300;
		camera.position.z = 5+zoom * Math.sin(lat/300);
		// trace(camera.position);
		scene.update();
	}

	function render(framebuffer: Framebuffer): Void {
		var g4 = framebuffer.g4;
		g4.begin();
		g4.clear(kha.Color.fromBytes(49, 61, 82));
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
