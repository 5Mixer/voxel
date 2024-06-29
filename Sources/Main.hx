package;

import haxe.zip.Uncompress;
import kha.math.Vector3;
import kha.Assets;
import kha.Framebuffer;
import kha.Scheduler;
import kha.System;

class Main {
	var scene:Scene;
	var camera:Camera;
	var player:Player;
	var explosives = new Array<Explosive>();
	var input:Input;
	var lineRenderer:LineRenderer;
	var entityRenderer:EntityRenderer;
	var connection:ServerConnection;

	var awaitingSprintStart = false;

	function new() {
		camera = new Camera();
		input = new Input(camera);
		player = new Player();
		lineRenderer = new LineRenderer(camera);
		entityRenderer = new EntityRenderer(camera, explosives);

		// Right left top bottom front back
		BlockRegistry.register(BlockIdentifier.Dirt, new Block("Dirt", 0, 0, 0, 0, 0, 0));
		BlockRegistry.register(BlockIdentifier.Grass, new Block("Grass", 1, 1, 2, 0, 1, 1));
		BlockRegistry.register(BlockIdentifier.Stone, new Block("Stone", 3, 3, 3, 3, 3, 3));

		connection = new ServerConnection();
		connection.receiveChunk = function(compressed) {
			var data = Uncompress.run(compressed);
			var cx = data.getInt32(0);
			var cy = data.getInt32(4);
			var cz = data.getInt32(8);
			scene.loadChunkData(cx, cy, cz, data);
		}
		connection.receiveBlock = function(x, y, z, b) {
			scene.setBlock(x, y, z, b);
		}
		scene = new Scene(camera, connection.requestChunk, connection.sendBlock);

		input.clickListeners.push(function(button) {
			scene.ray(button == 0);
		});
		input.jumpAttemptCallback = function() {
			player.jump();
		}

		input.forwardsListeners.push(function() {
			if (!awaitingSprintStart) {
				awaitingSprintStart = true;
				Scheduler.addTimeTask(function() {
					if (!player.sprinting)
						awaitingSprintStart = false;
				}, .3);
			} else {
				player.sprinting = true;
				awaitingSprintStart = false;
			}
		});
	}

	var frame = 0;
	function update():Void {
		camera.position = player.getHeadPosition();
		camera.fov = (player.sprinting ? 90 : 80) * Math.PI / 180;
		scene.update();
		player.update(input, scene, camera);
		for (explosive in explosives) explosive.update();

		if (input.rightMouseButtonDown && frame++ % 60 == 0) {
			var e = new Explosive();
			e.position = player.position.mult(1);
			e.position.y += 1;
			e.velocity = camera.getLookVector();
			explosives.push(e);
		}

		for (explosive in explosives) {
			var aabb = explosive.getAABB();
			var exploded = false;

			for (x in Math.floor(aabb.min.x)...Math.ceil(aabb.max.x))
				for (y in Math.floor(aabb.min.y)...Math.ceil(aabb.max.y))
					for (z in Math.floor(aabb.min.z)...Math.ceil(aabb.max.z))
						if (!scene.isAir(x, y, z))
							exploded = true;

			if (exploded) {
				for (secondary in explosives) {
					var delta = explosive.position.sub(secondary.position);
					if (delta.length < 8 && delta.length != 0) {
						secondary.velocity = secondary.velocity.sub(delta.mult(1/delta.length).mult(.5));
					}
				}

				var radius = 3;
				for (ox in -radius...radius) {
					for (oy in -radius...radius) {
						for (oz in -radius...radius) {
							if (Math.abs(ox)+Math.abs(oy)+Math.abs(oz) < radius) {
								scene.setBlock(
									Math.floor(explosive.position.x)+ox,
									Math.floor(explosive.position.y)+oy,
									Math.floor(explosive.position.z)+oz,
									BlockIdentifier.Air
								);
							}

						}
					}
				}
				explosives.remove(explosive);
			}
		}
	}

	function renderCubeOutline(x, y, z, col) {
		lineRenderer.renderAABB(new AABB(new Vector3(x, y, z), new Vector3(x + 1, y + 1, z + 1)), col);
	}

	function render(framebuffer:Framebuffer):Void {
		var g4 = framebuffer.g4;
		g4.begin();
		g4.clear(kha.Color.fromBytes(172, 219, 252), 1.0);
		scene.render(g4);
		entityRenderer.render(g4);
		g4.end();

		// lineRenderer.start(g4);
		// g4.clear(null, 1.0); // Clear depth
		// var playerGizmoPos = camera.position.add(camera.getLookVector().mult(5));
		// lineRenderer.renderLine(playerGizmoPos.add(new Vector3(0,0,0)), playerGizmoPos.add(new Vector3(1,0,0)), kha.Color.Red);
		// lineRenderer.renderLine(playerGizmoPos.add(new Vector3(0,0,0)), playerGizmoPos.add(new Vector3(0,1,0)), kha.Color.Green);
		// lineRenderer.renderLine(playerGizmoPos.add(new Vector3(0,0,0)), playerGizmoPos.add(new Vector3(0,0,1)), kha.Color.Blue);
		
		// var cs = Chunk.chunkSize;
		// var gridSize = 10;
		// for (x in 0...gridSize)
		// 	for (y in 0...gridSize) {
		// 		lineRenderer.renderLine(new Vector3(cs*x,cs*y,0), new Vector3(cs*x,cs*y,cs*gridSize), kha.Color.Black);
		// 		lineRenderer.renderLine(new Vector3(cs*x,0,cs*y), new Vector3(cs*x,cs*gridSize,cs*y), kha.Color.Black);
		// 		lineRenderer.renderLine(new Vector3(0,cs*x,cs*y), new Vector3(cs*gridSize,cs*x,cs*y), kha.Color.Black);
		// 	}

		// lineRenderer.end(g4);

		var g2 = framebuffer.g2;
		g2.begin(false);
		g2.color = kha.Color.White;
		g2.drawScaledImage(Assets.images.cursor, kha.Window.get(0).width / 2 - 16, kha.Window.get(0).height / 2 - 16, 32, 32);
		g2.end();
	}

	public static function main() {
		System.start({
			title: "Blocks",
			width: 800,
			height: 600,
			framebuffer: {samplesPerPixel: 0}
		}, function(_) {
			Assets.loadEverything(function() {
				var main = new Main();
				Scheduler.addTimeTask(function() {
					main.update();
				}, 0, 1 / 60);
				System.notifyOnFrames(function(framebuffers) {
					main.render(framebuffers[0]);
				});
			});
		});
	}
}
