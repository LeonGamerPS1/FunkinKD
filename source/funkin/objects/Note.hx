package funkin.objects;

class Note extends FlxSprite {
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
	public var sustainNote:Bool = false;
	public var prevNote:Note;
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

	public function new(time:Float = 0, data:Int = 0, sustainNote:Bool = false, ?isPixel:Bool = false, ?prevNote:Note, ?sustainSpeed:Float = 1,
			?conductor:Conductor) {
		super(0, -2000);

		this.data = data;
		this.isPixel = isPixel;
		this.time = time;
		this.sustainNote = sustainNote;
		this.prevNote = prevNote;
		this.conductor = conductor;
		texture = "notes";
		reloadNote(texture, isPixel, sustainSpeed);

		if (!sustainNote)
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

	override function update(elapsed:Float) {
		if (!mustHit) {
			if (!wasGoodHit && time <= conductor.songPosition) {
				if (!sustainNote || (prevNote.wasGoodHit && !ignoreNote))
					wasGoodHit = true;
			}
		}
		super.update(elapsed);
	}

	override function set_clipRect(rect:FlxRect):FlxRect {
		clipRect = rect;

		if (frames != null)
			frame = frames.frames[animation.frameIndex];

		return clipRect = rect;
	}

	function loadPixelNoteAnimations(tex:String, ?sustainSpeed:Float = 1) {
		pixelPerfectPosition = true;
		pixelPerfectRender = true;
		if (!sustainNote) {
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

			scale.x = 5;
			updateHitbox();
			if (prevNote != null && prevNote.sustainNote) {
				prevNote.playAnim("hold");
				prevNote.scale.y = 6 * (conductor.stepLength / 100 * 1.254 * sustainSpeed);
				prevNote.updateHitbox();
			}
		}
	}

	function loadDefaultNoteAnims(tex:String, ?sustainSpeed:Float = 1) {
		frames = Paths.getSparrowAtlas('noteSkins/$tex');

		animation.addByPrefix('arrow', '${directions[data % directions.length]}0', 24, false);
		animation.addByPrefix('hold', '${directions[data % directions.length]} hold piece', 24, false);
		animation.addByPrefix('end', '${directions[data % directions.length]} hold end', 24, false);

		setGraphicSize(width * 0.7);
		updateHitbox();

		if (sustainNote) {
			endBoi = true;
			animation.play('end');
			updateHitbox();

			antialiasing = true;
			if (prevNote != null && prevNote.sustainNote) {
				prevNote.animation.play("hold", true);
				prevNote.endBoi = false;
				prevNote.scale.y = 0.7 * (conductor.stepLength / 100 * 1.5 * sustainSpeed);
				prevNote.antialiasing = false;
				prevNote.updateHitbox();
			}
		}
		antialiasing = true;
	}

	function set_texture(value:String):String {
		reloadNote(value, isPixel);
		return texture = value;
	}

	public var offsetY:Float = 0;
	public var multAlpha:Float = 1;

	public function followStrumNote(strum:StrumNote, conductor:Conductor, ?songSpeed:Float = 1) {
		if (x != strum.x + offsetX)
			x = strum.x + offsetX;

		if (sustainNote)
			x = strum.x + (strum.width / 2) - (width / 2);

		alpha = strum.alpha * multAlpha;
		y = strum.y + (time - conductor.songPosition) * 0.45 * (songSpeed * (!strum.downScroll ? 1 : -1)) + offsetY;

		if (flipY != strum.downScroll && sustainNote)
			flipY = strum.downScroll;
		downscroll = strum.downScroll;

		if (strum.downScroll && sustainNote) {
			if (isPixel)
				y += 30;
			else
				y += 60;

			y -= (frameHeight * scale.y) - (swagWidth);
		}
	}

	inline public function clipToStrumNote(myStrum:StrumNote) {
		var center:Float = myStrum.y + myStrum.height / 2;

		if ((mustHit || !mustHit) && (wasGoodHit || (prevNote.wasGoodHit && !canBeHit(conductor)))) {
			var swagRect:FlxRect;

			swagRect = FlxRect.get(0, 0, frameWidth, frameHeight);

			if (myStrum.downScroll) {
				if (y - offset.y * scale.y + height >= center) {
					swagRect.width = frameWidth;
					swagRect.height = Std.int((center - y) / scale.y);
					swagRect.y = Std.int(frameHeight - swagRect.height);
				}
			} else if (y + offset.y * scale.y <= center) {
				swagRect.y = (center - y) / scale.y;
				swagRect.width = width / scale.x;
				swagRect.height = (height / scale.y) - swagRect.y;
			}

			clipRect = swagRect;
			swagRect.put();
		}
	}

	public var endBoi = false;

	public function isEndNote():Bool {
		if (!sustainNote)
			return false;
		return endBoi;
	}
}
