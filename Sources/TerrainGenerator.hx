package ;

import haxe.ds.StringMap;
import haxe.ds.ObjectMap;
import kha.math.Vector2i;
import haxe.ds.HashMap;

class TerrainWorldGenerator implements WorldGenerator {
    var perlin:hxnoise.Perlin;
    var perlinCache = new StringMap<Float>();
    public function new() {
        perlin = new hxnoise.Perlin();
    }
    public function getBlock(x:Int,y:Int,z:Int) {
        var cached = perlinCache.get('$x,$z');
        var height = cached ??
            perlin.OctavePerlin(x/10,z/10,.1, 1,.5,.25)*50-20;
        perlinCache.set('$x,$z', height);
        // var cave = perlin.OctavePerlin(x/2,z/2,y/4, 1, .5, .25) < .6;
        // return cave && y < height ? BlockIdentifier.Stone : BlockIdentifier.Air;
        return y < height ? BlockIdentifier.Grass : BlockIdentifier.Air;
    }
}