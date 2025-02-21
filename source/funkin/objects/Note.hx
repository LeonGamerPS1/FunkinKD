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

	public static var swagWidth:Float = 160 * 0.7;

	public var altNote:Bool = false;

	public var wasMissed:Bool = false;
	public var multSpeed:Float = 1;
	public var sustain:Sustain;

	public function canBeHit(conductor:Conductor):Bool {
		if (mustHit
			&& time > conductor.songPosition - (Conductor.safeZoneOffset)
			&& time < conductor.songPosition + (Conductor.safeZoneOffset * 0.5))
			return true;
		else
			return false;
	}

	public function new(time:Float = 0, data:Int = 0, ?isPixel:Bool = false, ?prevNote:Note, ?sustainSpeed:Float = 1, ?conductor:Conductor, sus:Bool = false) {
		super(0, -2000);

		this.data = data;
		this.isPixel = isPixel;
		this.time = time;
		this.prevNote = prevNote;
		this.conductor = conductor;
		isSustainNote = sus;
		texture = "notes";

		reloadNote(texture, isPixel, sustainSpeed);
		if (!isSustainNote)
			playAnim("arrow");
	}

	public function playAnim(s:String, force:Bool = false) {
		animation.play(s, force);
		centerOffsets();
		centerOrigin();
	}

	function reloadNote(tex:String = "notes", isPixel:Bool, ?sustainSpeed:Float = 1) {
		tex ??= "notes";
		if (PlayState.SONG.skin != null && PlayState.SONG.skin != "")
			tex = PlayState.SONG.skin;
		this.isPixel = isPixel;
		var prefix = isPixel ? "pixel/" : "";
		var path = Paths.img('noteSkins/$prefix$tex');
		if (!Assets.exists(path)) {
			trace(' "$path" doesnt exist, Reverting skin back to default');
			tex = "notes";
		}
		@:bypassAccessor
		texture = tex;

		if (!isPixel)
			loadDefaultNoteAnims(tex, sustainSpeed);
		else
			loadPixelNoteAnimations(tex, sustainSpeed);
	}

	var canDrawSustain:Bool = false;

	override function update(elapsed:Float) {
		if (!mustHit) {
			if (time <= conductor.songPosition)
				wasGoodHit = true;
		} else {
			if (!wasGoodHit && time <= conductor.songPosition + 50)
				if (!isSustainNote || (prevNote.wasGoodHit && !ignoreNote))
					botHit = true;
		}
		super.update(elapsed);
	}

	public var botHit = false;

	function loadPixelNoteAnimations(tex:String, ?sustainSpeed:Float = 1) {
		if (!isSustainNote) {
			loadGraphic(Paths.image('noteSkins/pixel/$tex'), true, 17, 17);

			animation.add('arrow', [data % 4 + 4], 12, false);
			setGraphicSize(width * 6);

			antialiasing = false;
			updateHitbox();
		} else {
			loadGraphic(Paths.image('noteSkins/pixel/${tex}ENDS'));
			width = width / 4;
			height = height / 5;
			loadGraphic(Paths.image('noteSkins/pixel/${tex}ENDS'), true, 7, 6);

			animation.add('hold', [data], 12, false);
			animation.add('end', [data + 4], 12, false);
			setGraphicSize(width * 6);
			playAnim("end");
			updateHitbox();

			if (prevNote != null && prevNote.isSustainNote) {
				prevNote.playAnim("hold");
				prevNote.scale.y = 6 * (conductor.stepLength / 100 * 1.5 * sustainSpeed);
				prevNote.updateHitbox();
			}
		}
	}

	override function draw() {
		if (!wasGoodHit || !wasHit)
			super.draw();
	}

	function loadDefaultNoteAnims(tex:String, ?sustainSpeed:Float = 1) {
		frames = Paths.getAtlas('noteSkins/$tex');

		animation.addByPrefix('arrow', '${directions[data % directions.length]}0', 24, false);
		animation.addByPrefix('hold', '${directions[data % directions.length]} hold piece', 24, false);
		animation.addByPrefix('end', '${directions[data % directions.length]} hold end', 24, false);

		setGraphicSize(width * 0.7);
		updateHitbox();

		if (isSustainNote && prevNote != null) {
			playAnim('end');
			scale.y = 1;
			updateHitbox();
			if (prevNote != null && prevNote.isSustainNote) {
				prevNote.playAnim('hold');
				prevNote.scale.y = 0.7 * (conductor.stepLength / 100 * 1.5 * sustainSpeed);
				prevNote.updateHitbox();
				prevNote.antialiasing = false;
			}
		}

		antialiasing = true;
	}

	function set_texture(value:String):String {
		texture = value;

		reloadNote(value, isPixel);
		return texture = value;
	}

	public var offsetY:Float = 0;
	public var multAlpha:Float = 1;

	public var distance:Float = 3000;

	public var copyX:Null<Bool> = true;
	public var copyY:Null<Bool> = true;
	public var copyAngle:Null<Bool> = true;
	public var copyAlpha:Null<Bool> = true;
	public var isSustainNote:Bool = false;

	public function followStrumNote(myStrum:StrumNote, conductor:Conductor, ?songSpeed:Float = 1) {
		this.strum = myStrum;

		songSpeed = FlxMath.roundDecimal(songSpeed, 2);

		var strumX:Float = myStrum.x;
		var strumY:Float = myStrum.y;
		var strumAngle:Float = myStrum.angle;
		var strumAlpha:Float = myStrum.alpha;
		var strumDirection:Float = myStrum.direction;

		distance = Math.floor((0.45 * (conductor.songPosition - time) * songSpeed * multSpeed));

		if (!myStrum.downScroll)
			distance *= -1;

		var angleDir = strumDirection * Math.PI / 180;

		if (copyAlpha)
			alpha = strumAlpha * multAlpha;

		if (copyX)
			x = strumX + offsetX + Math.cos(angleDir) * distance;
		if (isSustainNote)
			x = strumX + (strum.width / 2) - (width / 2) + Math.cos(angleDir) * distance;
		if (copyY)
			y = strumY + offsetY + 0 + Math.sin(angleDir) * distance;

		downscroll = strum.downScroll;
		if (wasGoodHit)
			setPosition(strumX + offsetX, strumY + offsetY);
	}

	public var glowing = false;
	public var tooLate:Bool = false;
}
