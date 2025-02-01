package funkin.objects;

import flixel.FlxSprite;

class StrumNote extends FlxSprite {
	public static var directions:Array<String> = ["left", "down", "up", "right"];

	public var texture(default, set):String;
	public var isPixel:Bool = false;

	public var data:Int = 0;
	public var resetTimer:Float = 0;
	public var downScroll:Bool = false;

	public function new(data:Int = 0, isPixel:Bool = false) {
		super();
		this.data = data;
		this.isPixel = isPixel;
		texture = "notes";
		playAnim("static");
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

	var confirm = [[12, 16], [13, 17], [14, 18], [15, 19]];

	function loadPixelNoteAnimations(tex:String = "notes") {
		loadGraphic(Paths.image('noteSkins/pixel/$tex'), true, 17, 17);
		animation.add('static', [data % 4], 12, false);
		animation.add('pressed', [data % 4 + 4, data % 4 + 8], 24, false);
		animation.add('confirm', confirm[data % confirm.length], 24, false);
		setGraphicSize(width * 6);
		updateHitbox();
	}

	function loadDefaultNoteAnims(tex:String) {
		frames = Paths.getSparrowAtlas('noteSkins/$tex');

		animation.addByPrefix('static', 'arrow${directions[data % directions.length].toUpperCase()}', 24, false);
		animation.addByPrefix('pressed', '${directions[data % directions.length]} press', 24, false);
		animation.addByPrefix('confirm', '${directions[data % directions.length]} confirm', 24, false);

		setGraphicSize(width * 0.7);
		updateHitbox();
		antialiasing = true;
	}

	function set_texture(value:String):String {
		reloadNote(value, isPixel);
		return texture = value;
	}

	override function update(elapsed:Float):Void {
		if (resetTimer > 0) {
			resetTimer -= elapsed;
			if (resetTimer < 0) {
				playAnim("static", true);
				resetTimer = 0;
			}
		}
		super.update(elapsed);
	}
}
