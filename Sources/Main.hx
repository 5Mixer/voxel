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
	var lineRenderer:LineRenderer;
	var connection:ServerConnection;

	var awaitingSprintStart = false;
	var sprinting = false;
	var worldLoaded = false;

	var jumps = 0;
	var maxJumps = 2;

	function new() {
		camera = new Camera();
		input = new Input(camera);
		scene = new Scene(camera);
		player = new Player();
		lineRenderer = new LineRenderer(camera);

		// Right left top bottom front back
		BlockRegistry.register(BlockIdentifier.Dirt, new Block("Dirt", 0, 0, 0, 0, 0, 0));
		BlockRegistry.register(BlockIdentifier.Grass, new Block("Grass", 1, 1, 2, 0, 1, 1));
		BlockRegistry.register(BlockIdentifier.Stone, new Block("Stone", 3, 3, 3, 3, 3, 3));

		connection = new ServerConnection();
		connection.receiveChunk = function(data) {
			var cx = data.getInt32(0);
			var cy = data.getInt32(4);
			var cz = data.getInt32(8);
			scene.loadChunkData(cx, cy, cz, data);
			if (!worldLoaded && cx == 0 && cy == 0 && cz == 0)
				worldLoaded = true;
		}
		connection.receiveBlock = function(x, y, z, b) {
			scene.setBlock(x, y, z, b);
		}
		scene.requestChunk = connection.requestChunk;
		scene.sendBlock = connection.sendBlock;

		input.clickListeners.push(function(button) {
			scene.ray(button == 0);
		});
		input.jumpAttemptCallback = function() {
			if (jumps < maxJumps) {
				player.velocity.y = .17;
				jumps++;
			}
		}

		input.forwardsListeners.push(function() {
			if (!awaitingSprintStart) {
				awaitingSprintStart = true;
				Scheduler.addTimeTask(function() {
					if (!sprinting)
						awaitingSprintStart = false;
				}, .3);
			} else {
				sprinting = true;
				awaitingSprintStart = false;
			}
		});
	}

	function update():Void {
		camera.position = player.position.add(new Vector3(0, player.size.y, 0));
		camera.fov = (sprinting ? 100 : 80) * Math.PI / 180;
		scene.update();
		player.update();

		for (i in 0...50)
			if (input.rightMouseButtonDown)
				scene.ray(false);

		var localMovementVector = new Vector2(0, 0);
		if (input.forwards) {
			localMovementVector.x += 1;
		} else {
			sprinting = false;
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
		var movement = FastMatrix3.rotation(Math.PI / 2 - camera.horizontalAngle)
			.multvec(localMovementVector.fast())
			.normalized()
			.mult(sprinting ? 10 / 60 : 5 / 60);

		if (!worldLoaded)
			return;

		// y movement and collision resolution
		player.position.y += player.velocity.y;
		var shouldMoveY = true;
		var aabb = player.getAABB();
		for (x in Math.floor(aabb.min.x)...Math.ceil(aabb.max.x))
			for (y in Math.floor(aabb.min.y)...Math.ceil(aabb.max.y))
				for (z in Math.floor(aabb.min.z)...Math.ceil(aabb.max.z))
					if (!scene.isAir(x, y, z)) {
						shouldMoveY = false;
						break;
					}
		if (!shouldMoveY) {
			if (player.velocity.y > 0) {
				player.position.y = Math.floor(aabb.max.y + player.velocity.y) - player.size.y;
				player.velocity.y = 0;
			} else {
				player.position.y = Math.ceil(aabb.min.y + player.velocity.y);
				jumps = 0;
				player.velocity.y = 0;

				if (input.space) {
					player.velocity.y = .17;
					jumps++;
				}
			}
		} else {
			player.velocity.y -= .01;
		}

		// x movement and collision resolution
		player.position.x += movement.x;

		var shouldMoveX = true;
		var aabb = player.getAABB();
		for (x in Math.floor(aabb.min.x)...Math.ceil(aabb.max.x))
			for (y in Math.floor(aabb.min.y)...Math.ceil(aabb.max.y))
				for (z in Math.floor(aabb.min.z)...Math.ceil(aabb.max.z))
					if (!scene.isAir(x, y, z)) {
						shouldMoveX = false;
						break;
					}
		if (!shouldMoveX) {
			player.position.x -= movement.x;
			sprinting = false;
		}

		// z movement and collision resolution
		player.position.z += movement.y;

		var shouldMoveZ = true;
		var aabb = player.getAABB();
		for (x in Math.floor(aabb.min.x)...Math.ceil(aabb.max.x))
			for (y in Math.floor(aabb.min.y)...Math.ceil(aabb.max.y))
				for (z in Math.floor(aabb.min.z)...Math.ceil(aabb.max.z))
					if (!scene.isAir(x, y, z)) {
						shouldMoveZ = false;
						break;
					}
		if (!shouldMoveZ) {
			player.position.z -= movement.y;
			sprinting = false;
		}
	}

	function renderAABB(aabb:AABB, col = kha.Color.Blue) {
		var min = aabb.min;
		var max = aabb.max;
		// Bottom of AABB
		lineRenderer.renderLine(new Vector3(min.x, min.y, min.z), new Vector3(max.x, min.y, min.z), col);
		lineRenderer.renderLine(new Vector3(min.x, min.y, min.z), new Vector3(min.x, min.y, max.z), col);
		lineRenderer.renderLine(new Vector3(max.x, min.y, max.z), new Vector3(min.x, min.y, max.z), col);
		lineRenderer.renderLine(new Vector3(max.x, min.y, max.z), new Vector3(max.x, min.y, min.z), col);
		// Sides of AABB
		lineRenderer.renderLine(new Vector3(min.x, min.y, min.z), new Vector3(min.x, max.y, min.z), col);
		lineRenderer.renderLine(new Vector3(max.x, min.y, min.z), new Vector3(max.x, max.y, min.z), col);
		lineRenderer.renderLine(new Vector3(min.x, min.y, max.z), new Vector3(min.x, max.y, max.z), col);
		lineRenderer.renderLine(new Vector3(max.x, min.y, max.z), new Vector3(max.x, max.y, max.z), col);
		// Top of AABB
		lineRenderer.renderLine(new Vector3(min.x, max.y, min.z), new Vector3(max.x, max.y, min.z), col);
		lineRenderer.renderLine(new Vector3(min.x, max.y, min.z), new Vector3(min.x, max.y, max.z), col);
		lineRenderer.renderLine(new Vector3(max.x, max.y, max.z), new Vector3(min.x, max.y, max.z), col);
		lineRenderer.renderLine(new Vector3(max.x, max.y, max.z), new Vector3(max.x, max.y, min.z), col);
	}

	function renderCubeOutline(x, y, z, col) {
		renderAABB(new AABB(new Vector3(x, y, z), new Vector3(x + 1, y + 1, z + 1)), col);
	}

	function render(framebuffer:Framebuffer):Void {
		var g4 = framebuffer.g4;
		g4.begin();
		g4.clear(kha.Color.fromBytes(0, 42, 57), 1.0);
		scene.render(g4);

		/*lineRenderer.start(g4);
			g4.clear(null, 1.0); // Clear depth
			var playerGizmoPos = camera.position.add(camera.getLookVector().mult(5));
			// lineRenderer.renderLine(playerGizmoPos.add(new Vector3(0,0,0)), playerGizmoPos.add(new Vector3(1,0,0)), kha.Color.Red);
			// lineRenderer.renderLine(playerGizmoPos.add(new Vector3(0,0,0)), playerGizmoPos.add(new Vector3(0,1,0)), kha.Color.Green);
			// lineRenderer.renderLine(playerGizmoPos.add(new Vector3(0,0,0)), playerGizmoPos.add(new Vector3(0,0,1)), kha.Color.Blue);
			lineRenderer.renderLine(new Vector3(0,1,0), new Vector3(0,1,5), kha.Color.Black);

			lineRenderer.end(g4); */

		g4.end();

		var g2 = framebuffer.g2;
		// g2.begin(false);
		// g2.color = kha.Color.White;
		// g2.drawScaledImage(Assets.images.cursor, kha.Window.get(0).width / 2 - 16, kha.Window.get(0).height / 2 - 16, 32, 32);
		// g2.end();
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
