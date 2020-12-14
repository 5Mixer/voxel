package ;

class TerrainWorldGenerator implements WorldGenerator {
    var perlin:hxnoise.Perlin;
    public function new() {
        perlin = new hxnoise.Perlin();
    }
    public function getBlock(x:Int,y:Int,z:Int) {
        var height = perlin.OctavePerlin(x/8,z/8,.1, 2,.5,.25)*50-40;
        var cave = perlin.OctavePerlin(x/2,z/2,y/4, 1, .5, .25) < .6;
        return cave && y < height ? BlockIdentifier.Stone : BlockIdentifier.Air;
    }
}