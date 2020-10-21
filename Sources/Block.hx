package ;

import kha.Color;

class Block {
	public var colour:Color;
	public var x:Int = 0;
	public var y:Int = 0;
	public var z:Int = 0;
	
	public function new(x,y,z) {
		colour = kha.Color.Green;
		this.x=x;
		this.y=y;
		this.z=z;
	}
}
