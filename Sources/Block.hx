package ;

class Block {
    public var name:String;

    public var rightTextureIndex:Int;
    public var leftTextureIndex:Int;
    public var topTextureIndex:Int;
    public var bottomTextureIndex:Int;
    public var frontTextureIndex:Int;
    public var backTextureIndex:Int;

    public function new(name, rightTextureIndex, leftTextureIndex, topTextureIndex, bottomTextureIndex, frontTextureIndex, backTextureIndex) {
        this.name = name;
        this.rightTextureIndex = rightTextureIndex;
        this.leftTextureIndex = leftTextureIndex;
        this.topTextureIndex = topTextureIndex;
        this.bottomTextureIndex = bottomTextureIndex;
        this.frontTextureIndex = frontTextureIndex;
        this.backTextureIndex = backTextureIndex;
    }
}