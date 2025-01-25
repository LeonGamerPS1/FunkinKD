package funkin.objects;

import flixel.FlxSprite;

class Note extends FlxSprite {
	public static var directions:Array<String> = ["purple", "blue", "green", "red"];

	public var texture(default, set):String;
	public var isPixel:Bool = false;

	public var data:Int = 0;

	public function new(data:Int = 0, isPixel:Bool = false) {
		super();

		this.data = data;
		this.isPixel = isPixel;
		texture = "notes";
		playAnim("arrow");
	}

	public function playAnim(s:String, force:Bool = false) {
		animation.play(s, force);
		centerOffsets();
		centerOrigin();
	}

	function reloadNote(tex:String = "notes", isPixel:Bool) {
		this.isPixel = isPixel;

		if (!isPixel)
			loadDefaultNoteAnims(tex);
		else
			loadPixelNoteAnimations(tex);
	}

	function loadPixelNoteAnimations(tex:String) {
		loadGraphic(Paths.image('noteSkins/pixel/$tex'), true, 17, 17);

		animation.add('arrow', [data % 4 + 4], 12, false);
		setGraphicSize(width * 6);

		pixelPerfectPosition = true;
		pixelPerfectRender = true;
		updateHitbox();
	}

	function loadDefaultNoteAnims(tex:String) {
		frames = Paths.getSparrowAtlas('noteSkins/$tex');

		animation.addByPrefix('arrow', '${directions[data % directions.length]}', 24, false);

		setGraphicSize(width * 0.7);
		updateHitbox();
		antialiasing = true;
	}

	function set_texture(value:String):String {
		reloadNote(value, isPixel);
		return texture = value;
	}
}
