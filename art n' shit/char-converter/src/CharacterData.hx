package;
typedef CharacterData = {
	var name:String;
	var flipX:Null<Bool>;
	var texture_path:String;
	var health_icon:String;
	var health_colors:Array<Int>;
	var animations:Array<AnimationData>;
	var scale:Null<Float>;
	var dancer:Null<Bool>;
	var singDuration:Null<Float>;

	@:optional var camera_position:Array<Float>;
	@:optional var position:Array<Float>;

	@:optional var antialiasing:Null<Bool>;
	@:optional var pixelated:Null<Bool>;
}

typedef AnimationData = {
	var name:String;
	var prefix:String;
	var fps:Int;
	var looped:Bool;
	var x:Float;
	var y:Float;
	var indices:Array<Int>;
}