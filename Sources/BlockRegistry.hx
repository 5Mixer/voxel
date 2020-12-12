package ;

class BlockRegistry {
    static var blockTypes:Map<Int, Block> = [];
    public static function register(type:Int, block:Block) {
        blockTypes[type] = block;
    }
}