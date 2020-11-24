package ;

class FlatWorldGenerator implements WorldGenerator {
    public function new() {

    }
    public function getBlock(x:Int,y:Int,z:Int) {
        return (y < 0) ? 1 : 0;
    }
}