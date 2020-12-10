package ;

class BlockRegistry {
    static var blockTypes:Map<BlockIdentifier, Block> = [];
    public static function register(type:BlockIdentifier, block:Block) {
        blockTypes[type] = block;
    }
}