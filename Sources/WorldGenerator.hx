package ;

/* Generates an _implicit_ world. When chunks are first loaded, they sample this worldGenerator for block information.
   This should be infinite, with as light state as possible.
   */
interface WorldGenerator {
    public function getBlock(x:Int,y:Int,z:Int):Int;
}