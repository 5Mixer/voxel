package;

import kha.math.Vector3;
import kha.graphics5_.VertexStructure;
import haxe.io.Bytes;
import haxe.Timer;
import TerrainGenerator.TerrainWorldGenerator;
import haxe.ds.Vector;
import kha.Shaders;
import kha.graphics4.*;

class Scene {
	var structure:VertexStructure;
	var vertexBuffer:VertexBuffer;
	var indexBuffer:IndexBuffer;
	var pipeline:PipelineState;

	var mvpID:ConstantLocation;
	var textureID:TextureUnit;

	var camera:Camera;
	var chunks = new Vector<Chunk>(loadedChunksPerDimension * loadedChunksPerDimension * loadedChunksPerDimension);
	var newChunks = new Vector<Chunk>(loadedChunksPerDimension * loadedChunksPerDimension * loadedChunksPerDimension);
	var chunkData = new Map<String, Bytes>();

	var generator:WorldGenerator;

	var prevCameraChunk = '';

	public var requestChunk:(cx:Int, cy:Int, cz:Int) -> Void;
	public var sendBlock:(x:Int, y:Int, z:Int, b:Int) -> Void;

	static var radius = 2;
	static var loadedChunksPerDimension = radius * 2 + 1; // -radius, 0, +radius
	static var loadedChunksPerDimensionSquared = loadedChunksPerDimension * loadedChunksPerDimension;
	static var loadedChunksPerDimensionCubed = loadedChunksPerDimension * loadedChunksPerDimension * loadedChunksPerDimension;

	var cameraChunkX = 0;
	var cameraChunkY = 0;
	var cameraChunkZ = 0;

	var chunkArrayOffsetX = 0;
	var chunkArrayOffsetY = 0;
	var chunkArrayOffsetZ = 0;

	var chunksInView = [
		for (cx in -radius + 1...radius)
			for (cy in -radius + 1...radius)
				for (cz in -radius + 1...radius)
					new Vector3(cx, cy, cz)
	];

	public function new(camera:Camera) {
		this.camera = camera;
		generator = new TerrainWorldGenerator();

		// kha.Assets.images.sprites.generateMipmaps(1);

		setupPipeline();
		chunksInView.sort(function(a, b) return a.length > b.length ? 1 : -1);
	}

	public function getChunk(cx:Int, cy:Int, cz:Int) {
		if (cx - chunkArrayOffsetX + radius < 0 || cx - chunkArrayOffsetX + radius >= loadedChunksPerDimension)
			return null;
		if (cy - chunkArrayOffsetY + radius < 0 || cy - chunkArrayOffsetY + radius >= loadedChunksPerDimension)
			return null;
		if (cz - chunkArrayOffsetZ + radius < 0 || cz - chunkArrayOffsetZ + radius >= loadedChunksPerDimension)
			return null;

		return chunks[
			(cx - chunkArrayOffsetX + radius) * loadedChunksPerDimensionSquared + (cy - chunkArrayOffsetY + radius) * loadedChunksPerDimension + (cz
				- chunkArrayOffsetZ + radius)
		];
	}

	public function getChunkUnsafe(cx:Int, cy:Int, cz:Int) {
		return chunks[
			(cx - chunkArrayOffsetX + radius) * loadedChunksPerDimensionSquared + (cy - chunkArrayOffsetY + radius) * loadedChunksPerDimension + (cz
				- chunkArrayOffsetZ + radius)
		];
	}

	public function registerChunk(cx:Int, cy:Int, cz:Int, chunk:Chunk) {
		chunks[
			(cx - chunkArrayOffsetX + radius) * loadedChunksPerDimensionSquared + (cy - chunkArrayOffsetY + radius) * loadedChunksPerDimension + (cz
				- chunkArrayOffsetZ + radius)
		] = chunk;
	}

	inline function chunkMod(n:Int):Int {
		// Mod (%) normally wraps negative numbers so that -5 % 4 = -1. It should = 4
		return (n % Chunk.chunkSize + Chunk.chunkSize) % Chunk.chunkSize;
	}

	inline public function getBlock(x, y, z):Null<Int> {
		var chunk = getChunk(Math.floor(x / Chunk.chunkSize), Math.floor(y / Chunk.chunkSize), Math.floor(z / Chunk.chunkSize));
		if (chunk == null)
			return null;
		return chunk.getBlock(chunkMod(x), chunkMod(y), chunkMod(z));
	}

	inline public function getBlockUnsafe(x, y, z):Null<Int> {
		return getChunkUnsafe(Math.floor(x / Chunk.chunkSize), Math.floor(y / Chunk.chunkSize),
			Math.floor(z / Chunk.chunkSize)).getBlock(chunkMod(x), chunkMod(y), chunkMod(z));
	}

	inline public function isCoordinateOnChunkBound(n:Int) {
		return Math.abs(n % Chunk.chunkSize) <= 1;
	}

	public function setBlock(x, y, z, b, send = false) {
		var chunk = getChunk(Math.floor(x / Chunk.chunkSize), Math.floor(y / Chunk.chunkSize), Math.floor(z / Chunk.chunkSize));
		if (chunk == null)
			return;

		if (send) {
			sendBlock(x, y, z, b);
		}

		// Set neighboring chunks to dirty geom so that lighting, ao, etc is recalculated
		for (xOffset in -1...2)
			for (yOffset in -1...2)
				for (zOffset in -1...2)
					getChunk(Math.floor((x + xOffset) / Chunk.chunkSize), Math.floor((y + yOffset) / Chunk.chunkSize),
						Math.floor((z + zOffset) / Chunk.chunkSize)).dirtyGeometry = true;

		chunk.setBlock(chunkMod(x), chunkMod(y), chunkMod(z), b);
	}

	inline public function isAir(x:Int, y:Int, z:Int) {
		return getBlock(x, y, z) == null || getBlock(x, y, z) == 0;
	}

	inline public function isExposed(x:Int, y:Int, z:Int) {
		return getBlock(x, y, z) == null || getBlock(x, y, z) == 0;
	}

	inline public function isExposedUnsafe(x:Int, y:Int, z:Int) {
		return getBlockUnsafe(x, y, z) == 0;
	}

	function setupPipeline() {
		// Vertex structure
		structure = new VertexStructure();
		structure.add("pos", VertexData.Float32_3X);
		structure.add("uv", VertexData.Float32_2X);
		structure.add("colour", VertexData.Float32_1X);

		// Pipeline
		pipeline = new PipelineState();
		pipeline.inputLayout = [structure];
		pipeline.fragmentShader = Shaders.block_frag;
		pipeline.vertexShader = Shaders.block_vert;

		pipeline.depthWrite = true;
		pipeline.depthMode = CompareMode.Less;

		pipeline.colorAttachmentCount = 1;
		pipeline.colorAttachments[0] = kha.graphics4.TextureFormat.RGBA32;
		pipeline.depthStencilAttachment = kha.graphics4.DepthStencilFormat.Depth16;
		pipeline.cullMode = Clockwise;

		pipeline.compile();

		// Graphics variables
		mvpID = pipeline.getConstantLocation("MVP");
		textureID = pipeline.getTextureUnit("textureSampler");
	}

	function shouldGenerateChunkGeometry(cx, cy, cz) {
		return (getChunk(cx + 1, cy, cz) != null)
			&& (getChunk(cx - 1, cy, cz) != null)
			&& (getChunk(cx, cy, cz + 1) != null)
			&& (getChunk(cx, cy, cz - 1) != null)
			&& (getChunk(cx + 1, cy, cz + 1) != null)
			&& (getChunk(cx + 1, cy, cz - 1) != null)
			&& (getChunk(cx - 1, cy, cz + 1) != null)
			&& (getChunk(cx - 1, cy, cz - 1) != null)
			&& (getChunk(cx, cy - 1, cz) != null)
			&& (getChunk(cx, cy + 1, cz) != null);
	}

	public function loadChunkData(cx:Int, cy:Int, cz:Int, data) {
		chunkData.set('$cx,$cy,$cz', data);
		var chunk = getChunk(cx, cy, cz);
		if (chunk != null) {
			chunk.loadData(data);
		}

		for (xOffset in -1...2)
			for (yOffset in -1...2)
				for (zOffset in -1...2)
					if (getChunk(cx + xOffset, cy + yOffset, cz + zOffset) != null)
						getChunk(cx + xOffset, cy + yOffset, cz + zOffset).dirtyGeometry = true;
	}

	var faceCullBuffer = Bytes.alloc(Chunk.chunkSizeCubed);
	var total = 0.;
	var total2 = 0.;

	function constructChunkGeometry(chunk:Chunk) {
		chunk.dirtyGeometry = false;

		if (!chunk.visible)
			return;

		var chunkOriginWorldscaleX = chunk.wx * Chunk.chunkSize;
		var chunkOriginWorldscaleY = chunk.wy * Chunk.chunkSize;
		var chunkOriginWorldscaleZ = chunk.wz * Chunk.chunkSize;

		var rightChunk = getChunkUnsafe(chunk.wx + 1, chunk.wy, chunk.wz);
		var leftChunk = getChunkUnsafe(chunk.wx - 1, chunk.wy, chunk.wz);
		var topChunk = getChunkUnsafe(chunk.wx, chunk.wy + 1, chunk.wz);
		var bottomChunk = getChunkUnsafe(chunk.wx, chunk.wy - 1, chunk.wz);
		var frontChunk = getChunkUnsafe(chunk.wx, chunk.wy, chunk.wz + 1);
		var backChunk = getChunkUnsafe(chunk.wx, chunk.wy, chunk.wz - 1);

		faceCullBuffer.fill(0, Chunk.chunkSizeCubed, (1 << 6) - 1); // Must always reset as buffer is reused.
		var faces = 0;
		var start = Timer.stamp();
		for (blockIndex in 0...Chunk.chunkSizeCubed) {
			if (chunk.blocks.get(blockIndex) == 0)
				continue;

			var lx = Math.floor(blockIndex / Chunk.chunkSizeSquared);
			var ly = Math.floor(blockIndex / Chunk.chunkSize) % Chunk.chunkSize;
			var lz = blockIndex % Chunk.chunkSize;

			var faceBitmap = (1 << 6) - 1;

			// Right face culling
			if (lx != Chunk.chunkSize - 1 && chunk.getBlock(lx + 1, ly, lz) == 0 || lx == Chunk.chunkSize - 1 && rightChunk.getBlock(0, ly, lz) == 0) {
				faceBitmap &= ~(1 << Side.Right);
				faces++;
			}

			// Left face culling
			if (lx != 0 && chunk.getBlock(lx - 1, ly, lz) == 0 || lx == 0 && leftChunk.getBlock(Chunk.chunkSize - 1, ly, lz) == 0) {
				faceBitmap &= ~(1 << Side.Left);
				faces++;
			}

			// Top face culling
			if (ly != Chunk.chunkSize - 1 && chunk.getBlock(lx, ly + 1, lz) == 0 || ly == Chunk.chunkSize - 1 && topChunk.getBlock(lx, 0, lz) == 0) {
				faceBitmap &= ~(1 << Side.Up);
				faces++;
			}

			// Down face culling
			if (ly != 0 && chunk.getBlock(lx, ly - 1, lz) == 0 || ly == 0 && bottomChunk.getBlock(lx, Chunk.chunkSize - 1, lz) == 0) {
				faceBitmap &= ~(1 << Side.Down);
				faces++;
			}

			// Front face culling
			if (lz != Chunk.chunkSize - 1 && chunk.getBlock(lx, ly, lz + 1) == 0 || lz == Chunk.chunkSize - 1 && frontChunk.getBlock(lx, ly, 0) == 0) {
				faceBitmap &= ~(1 << Side.Front);
				faces++;
			}

			// Back face culling
			if (lz != 0 && chunk.getBlock(lx, ly, lz - 1) == 0 || lz == 0 && backChunk.getBlock(lx, ly, Chunk.chunkSize - 1) == 0) {
				faceBitmap &= ~(1 << Side.Back);
				faces++;
			}
			faceCullBuffer.set(blockIndex, faceBitmap);
		}

		// All filled.
		if (faces == 0) {
			chunk.visible = false;
			return;
		} else {
			total += Timer.stamp() - start;

			trace('Built chunk ${chunk.wx} ${chunk.wy} ${chunk.wz} in ${Timer.stamp() - start}, total: $total');
		}
		var start = Timer.stamp();

		// Stores the current quads four AO values, so the quad may be index flipped if required
		var ao = new Vector<Float>(4);

		var vertexIndex = 0;

		chunk.vertexBuffer = new VertexBuffer(faces * 4, structure, StaticUsage);
		var vertexBufferData = chunk.vertexBuffer.lock();

		// Load the generated index data into a buffer
		chunk.indexBuffer = new IndexBuffer(faces * 6, StaticUsage);
		var indexBufferData = chunk.indexBuffer.lock();

		var vertexDataIndex = 0;
		var indexDataIndex = 0;

		var blockIndex = 0;
		for (lx in 0...Chunk.chunkSize) {
			var x = chunkOriginWorldscaleX + lx;

			for (ly in 0...Chunk.chunkSize) {
				var y = chunkOriginWorldscaleY + ly;

				for (lz in 0...Chunk.chunkSize) {
					var block = chunk.blocks.get(blockIndex++);

					if (block == 0) {
						continue;
					}

					var z = chunkOriginWorldscaleZ + lz;

					var blockTextureX = block % 16;
					var blockTextureY = Math.floor(block / 16);

					for (face in 0...6) {
						if ((faceCullBuffer.get(blockIndex - 1) & (1 << face)) != 0) // Skip obscured faced
							continue;

						for (triangleVertex in 0...4) {
							var v = face * 4 + triangleVertex; // v is the [0-24) vertices of the cube

							// position (xyz)
							vertexBufferData.set(vertexDataIndex++, (CubeGeometry.vertices[v * 3 + 0] + x)); // pos x
							vertexBufferData.set(vertexDataIndex++, (CubeGeometry.vertices[v * 3 + 1] + y)); // pos y
							vertexBufferData.set(vertexDataIndex++, (CubeGeometry.vertices[v * 3 + 2] + z)); // pos z

							// texture (uv)
							var textureU = (CubeGeometry.uv[v * 2] + blockTextureX) / 16;
							var textureV = (CubeGeometry.uv[v * 2 + 1] + blockTextureY) / 16;
							vertexBufferData.set(vertexDataIndex++, textureU);
							vertexBufferData.set(vertexDataIndex++, textureV);

							// colour (rgb)
							var side1 = false, side2 = false, corner = false;

							// Map the internal cube coordinates to -1 and 1 for ease of AO when comparing with nearby cubes
							var xVertexOffset = CubeGeometry.vertices[v * 3 + 0] == 1 ? 1 : -1;
							var yVertexOffset = CubeGeometry.vertices[v * 3 + 1] == 1 ? 1 : -1;
							var zVertexOffset = CubeGeometry.vertices[v * 3 + 2] == 1 ? 1 : -1;

							// Left and right adjacency tests for AO
							if (face == Side.Left || face == Side.Right) {
								side1 = !isExposedUnsafe(x + xVertexOffset, y + yVertexOffset, z);
								side2 = !isExposedUnsafe(x + xVertexOffset, y, z + zVertexOffset);
							}
							// Up and down adjacency tests for AO
							if (face == Side.Up || face == Side.Down) {
								side1 = !isExposedUnsafe(x + xVertexOffset, y + yVertexOffset, z);
								side2 = !isExposedUnsafe(x, y + yVertexOffset, z + zVertexOffset);
							}
							// Front and back adjacency tests for AO
							if (face == Side.Front || face == Side.Back) {
								side1 = !isExposedUnsafe(x + xVertexOffset, y, z + zVertexOffset);
								side2 = !isExposedUnsafe(x, y + yVertexOffset, z + zVertexOffset);
							}

							// Find corner for AO
							corner = !isExposedUnsafe(x + xVertexOffset, y + yVertexOffset, z + zVertexOffset);

							// Absence of corner is irrelevant if both sides obscure corner
							var light = if (side1 && side2) {
								0;
							} else {
								// Subtract light linearly by number of adjacent blocks
								(3 - ((side1 ? 1 : 0) + (side2 ? 1 : 0) + (corner ? 1 : 0))) / 3;
							};

							light = .5 + .5 * light;

							// Store this quad vertex in quad AO working array, so the quad indexes can be flipped if it makes AO look nicer.
							ao[triangleVertex] = light;
							vertexBufferData.set(vertexDataIndex++, light);
						}

						// Register quad as two triangles through index buffer
						// Flip if AO is backwards
						if (ao[0] + ao[2] > ao[1] + ao[3]) {
							indexBufferData.set(indexDataIndex++, (vertexIndex + 0));
							indexBufferData.set(indexDataIndex++, (vertexIndex + 1));
							indexBufferData.set(indexDataIndex++, (vertexIndex + 2));

							indexBufferData.set(indexDataIndex++, (vertexIndex + 0));
							indexBufferData.set(indexDataIndex++, (vertexIndex + 2));
							indexBufferData.set(indexDataIndex++, (vertexIndex + 3));
						} else {
							indexBufferData.set(indexDataIndex++, (vertexIndex + 1));
							indexBufferData.set(indexDataIndex++, (vertexIndex + 2));
							indexBufferData.set(indexDataIndex++, (vertexIndex + 3));

							indexBufferData.set(indexDataIndex++, (vertexIndex + 1));
							indexBufferData.set(indexDataIndex++, (vertexIndex + 3));
							indexBufferData.set(indexDataIndex++, (vertexIndex + 0));
						}
						vertexIndex += 4;
					}
				}
			}
		}
		chunk.vertexBuffer.unlock();
		chunk.indexBuffer.unlock();

		total2 += Timer.stamp() - start;

		trace('Finished data for ${chunk.wx} ${chunk.wy} ${chunk.wz}, faces: $faces, ${chunk.vertexBuffer.count() * structure.byteSize()} bytes, in ${Timer.stamp() - start}, total: $total2');
	}

	var reusableChunkPool = [];
	var firstUpdate = true;

	public function update() {
		cameraChunkX = Math.floor(camera.position.x / Chunk.chunkSize);
		cameraChunkY = Math.floor(camera.position.y / Chunk.chunkSize);
		cameraChunkZ = Math.floor(camera.position.z / Chunk.chunkSize);
		var cameraChunk = '$cameraChunkX,$cameraChunkY,$cameraChunkZ';

		var start = Timer.stamp();

		if (cameraChunk != prevCameraChunk || true) {
			var index = 0;
			var reusedChunks = []; // Stores retained chunks so that they are not destroyed.
			for (cx in -radius...radius + 1) {
				for (cy in -radius...radius + 1) {
					for (cz in -radius...radius + 1) {
						var existingChunk = getChunk(cx + cameraChunkX, cy + cameraChunkY,
							cz + cameraChunkZ); // Note cameraChunk != chunkArrayOffset yet, important.

						if (existingChunk != null) {
							newChunks[index] = existingChunk;
							reusedChunks.push(existingChunk);
						} else {
							if (reusableChunkPool.length > 0) {
								newChunks[index] = reusableChunkPool.pop();
							} else {
								newChunks[index] = new Chunk(cameraChunkX + cx, cameraChunkY + cy, cameraChunkZ + cz);
							}

							if (chunkData.exists('${cameraChunkX + cx},${cameraChunkY + cy},${cameraChunkZ + cz}')) {
								newChunks[index].loadData(chunkData.get('${cameraChunkX + cx},${cameraChunkY + cy},${cameraChunkZ + cz}'));
							} else {
								requestChunk(cameraChunkX + cx, cameraChunkY + cy, cameraChunkZ + cz);
							}
						}
						index++;
					}
				}
			}

			if (firstUpdate) {
				trace("Time: " + (Timer.stamp() - start));
				firstUpdate = false;
			}

			for (chunk in chunks)
				if (chunk != null && !reusedChunks.contains(chunk)) {
					chunk.destroyGeometry();
					reusableChunkPool.push(chunk);
				}

			chunks = newChunks.copy();
			chunkArrayOffsetX = cameraChunkX;
			chunkArrayOffsetY = cameraChunkY;
			chunkArrayOffsetZ = cameraChunkZ;
		}

		// Generate geom for one unit smaller than radius square (allows proper AO etc)
		for (chunkOffset in chunksInView) {
			var chunk = getChunk(cameraChunkX
				+ Math.floor(chunkOffset.x), cameraChunkY
				+ Math.floor(chunkOffset.y), cameraChunkZ
				+ Math.floor(chunkOffset.z));
			if (chunk != null && chunk.dirtyGeometry && shouldGenerateChunkGeometry(chunk.wx, chunk.wy, chunk.wz)) {
				constructChunkGeometry(chunk);
				continue; // Only generate one chunk per frame
			}
		}

		prevCameraChunk = cameraChunk + "";
	}

	public function render(g:Graphics) {
		g.setPipeline(pipeline);

		if (camera.mvpDirty)
			g.setMatrix(mvpID, camera.getMVP());
		g.setTexture(textureID, kha.Assets.images.sprites);
		g.setTextureParameters(textureID, Clamp, Clamp, TextureFilter.PointFilter, TextureFilter.PointFilter, MipMapFilter.NoMipFilter);

		for (chunk in chunks) {
			if (chunk == null || !chunk.hasGeometry()) {
				continue;
			}
			g.setVertexBuffer(chunk.vertexBuffer);
			g.setIndexBuffer(chunk.indexBuffer);
			g.drawIndexedVertices();
			continue;
		}
	}

	public function ray(place) {
		var look = camera.getLookVector().normalized();
		var stepSize = .1;
		var delta = look.mult(stepSize);
		var rayBlock = 0;
		var iterations = 0;
		// var rayLength = 10;
		var rayLength = 50;
		var rayPos = camera.position.mult(1);
		while (rayBlock == 0 && iterations++ < rayLength / stepSize) {
			rayPos = rayPos.add(delta);
			rayBlock = getBlock(Math.floor(rayPos.x), Math.floor(rayPos.y), Math.floor(rayPos.z));
		}

		if (iterations >= rayLength / stepSize)
			return; // Don't do anything if ray extends outside reach

		if (!place) {
			for (xo in -1...2)
				for (yo in -1...2)
					for (zo in -1...2)
						setBlock(Math.floor(rayPos.x) + xo, Math.floor(rayPos.y) + yo, Math.floor(rayPos.z) + zo, 0, true);
		} else {
			var rayEnd = rayPos.sub(delta);
			setBlock(Math.floor(rayEnd.x), Math.floor(rayEnd.y), Math.floor(rayEnd.z), Math.ceil(Math.random() * 4), true);
		}
	}
}
