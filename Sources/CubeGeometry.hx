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
		
		2, 1, //left
		2, 0,
		1, 0,
		1, 1,
		
		3, 0, //Up/top
		2, 0,
		2, 1,
		3, 1,
		
		4, 0, //Bottom/down
		3, 0,
		3, 1,
		4, 1,
		
		4, 1, //front
		5, 1,
		5, 0,
		4, 0,
		
		6, 0, //back
		5, 0,
		5, 1,
		6, 1
	];
}