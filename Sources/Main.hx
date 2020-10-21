package;

import kha.Assets;
import kha.Framebuffer;
import kha.Scheduler;
import kha.System;

class Main {
	var scene:Scene;
	function new () {
		scene = new Scene();
	}

	function update(): Void {
		scene.update();
	}

	function render(framebuffer: Framebuffer): Void {
		var g4 = framebuffer.g4;
		g4.begin();
		g4.clear();
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
