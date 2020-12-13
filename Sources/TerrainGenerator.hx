package ;

import hxnoise.DiamondSquare;

class TerrainWorldGenerator implements WorldGenerator {
    // var perlin:hxnoise.Perlin;
    var noise:hxnoise.DiamondSquare;
    public function new() {
        // perlin = new hxnoise.Perlin();
        noise = new DiamondSquare(256,256,64,2,function(){return Math.random()-.5;});
        noise.diamondSquare();
    }
    public function getBlock(x:Int,y:Int,z:Int) {
        return y < Math.random() * 10 ? BlockIdentifier.Grass : BlockIdentifier.Air;
        // var height = perlin.OctavePerlin(x/8,z/8,.1, 2,.5,.25)*50-40;
        // var cave = perlin.OctavePerlin(x/2,z/2,y/4, 1, .5, .25) < .6;
        // return cave && y < height ? BlockIdentifier.Stone : BlockIdentifier.Air;
    }
}