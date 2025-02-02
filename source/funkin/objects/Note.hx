package funkin.objects;

class Note extends FlxSprite {
	public static var noteScale(default, null):Float = 0.7;
	public static var directions:Array<String> = ["purple", "blue", "green", "red"];

	public var texture(default, set):String;
	public var isPixel:Bool = false;

	public var data:Int = 0;
	public var time:Float = 0;
	public var mustHit:Bool = false;
	public var wasHit:Bool = false;
	public var wasGoodHit:Bool = false;

	public var scrollSpeed:Float = 1;
	public var length:Float = 500 / 1000;

	public var downscroll:Bool = false;
	public var prevNote:Note;
	public var strum:StrumNote;
	public var conductor:Conductor;
	public var offsetX:Float = 0;
	public var ignoreNote:Bool = false;

	public var parent:Note;

	public static var swagWidth:Float = (160 / 2) * 0.7;

	public function canBeHit(conductor:Conductor):Bool {
		if (mustHit
			&& time > conductor.songPosition - (Conductor.safeZoneOffset)
			&& time < conductor.songPosition + (Conductor.safeZoneOffset * 0.5))
			return true;
		else
			return false;
	}

	public function new(time:Float = 0, data:Int = 0, ?isPixel:Bool = false, ?prevNote:Note, ?sustainSpeed:Float = 1, ?conductor:Conductor) {
		super(0, -2000);

		this.data = data;
		this.isPixel = isPixel;
		this.time = time;
		this.prevNote = prevNote;
		this.conductor = conductor;
		texture = "notes";

		reloadNote(texture, isPixel, sustainSpeed);
		playAnim("arrow");
	}

	public function playAnim(s:String, force:Bool = false) {
		animation.play(s, force);
		centerOffsets();
		centerOrigin();
	}

	function reloadNote(tex:String = "notes", isPixel:Bool, ?sustainSpeed:Float = 1) {
		this.isPixel = isPixel;

		if (!isPixel)
			loadDefaultNoteAnims(tex, sustainSpeed);
		else
			loadPixelNoteAnimations(tex, sustainSpeed);
	}

	var canDrawSustain:Bool = false;

	override function update(elapsed:Float) {
		if (!mustHit)
			if (!wasGoodHit && time <= conductor.songPosition)
				wasGoodHit = true;
		
		super.update(elapsed);
	}

	function loadPixelNoteAnimations(tex:String, ?sustainSpeed:Float = 1) {
		pixelPerfectPosition = true;
		pixelPerfectRender = true;

		loadGraphic(Paths.image('noteSkins/pixel/$tex'), true, 17, 17);

		animation.add('arrow', [data % 4 + 4], 12, false);
		setGraphicSize(width * 6);

		antialiasing = false;
		updateHitbox();
	}

	function loadDefaultNoteAnims(tex:String, ?sustainSpeed:Float = 1) {
		frames = Paths.getSparrowAtlas('noteSkins/$tex');

		animation.addByPrefix('arrow', '${directions[data % directions.length]}0', 24, false);
		animation.addByPrefix('hold', '${directions[data % directions.length]} hold piece', 24, false);
		animation.addByPrefix('end', '${directions[data % directions.length]} hold end', 24, false);

		setGraphicSize(width * 0.7);
		updateHitbox();

		antialiasing = true;
		if(sustain != null)
			sustain.antialiasing = antialiasing;
	}

	function set_texture(value:String):String {
		reloadNote(value, isPixel);
		return texture = value;
	}

	public var offsetY:Float = 0;
	public var multAlpha:Float = 1;
	public var sustain:Sustain;

	public function followStrumNote(strum:StrumNote, conductor:Conductor, ?songSpeed:Float = 1) {
		this.strum = strum;
		if (x != strum.x + offsetX)
			x = strum.x + offsetX;

		alpha = strum.alpha * multAlpha;
		y = strum.y + (time - conductor.songPosition) * 0.45 * (songSpeed * (!strum.downScroll ? 1 : -1)) + offsetY;

		downscroll = strum.downScroll;
	}

	override function draw() {
		if (sustain != null && downscroll)
			canDrawSustain = (y > 0);
		else
			
			canDrawSustain = true;

			try {
		if (sustain != null)
			sustain.draw();
	}
	catch(e)
	{
		trace(e);
	}
		if (!wasGoodHit)
			super.draw();
	}

	override function destroy() {
		if (sustain != null)
			sustain.destroy();

		super.destroy();
	}
}
