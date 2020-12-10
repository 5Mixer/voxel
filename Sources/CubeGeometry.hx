package ;

class CubeGeometry {
	public static final vertices = [
		1, 0, 0, // right
		1, 1, 0,
		1, 1, 1,
		1, 0, 1,
		
		0, 0, 1, // left
		0, 1, 1,
		0, 1, 0,
		0, 0, 0,
		
		1, 1, 0, // top
		0, 1, 0,
		0, 1, 1,
		1, 1, 1,
		
		1, 0, 1, // bottom
		0, 0, 1,
		0, 0, 0,
		1, 0, 0,

		0, 0, 1, // front
		1, 0, 1,
		1, 1, 1,
		0, 1, 1,

		0, 1, 0, // back
		1, 1, 0,
		1, 0, 0,
		0, 0, 0
	];
	public static final uv = [
		1, 1, //right
		1, 0,
		0, 0,
		0, 1,
		
		1, 1, //left
		1, 0,
		0, 0,
		0, 1,
		
		1, 0, //Up/top
		0, 0,
		0, 1,
		1, 1,
		
		1, 0, //Bottom/down
		0, 0,
		0, 1,
		1, 1,
		
		1, 1, //front
		0, 1,
		0, 0,
		1, 0,
		
		1, 0, //back
		0, 0,
		0, 1,
		1, 1
	];
}