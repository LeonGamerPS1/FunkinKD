package funkin.objects;

class HealthIcon extends FlxSprite {
	/**
	 * Used for FreeplayState! If you use it elsewhere, prob gonna annoying
	 */
	public var sprTracker:FlxSprite;


	/**
	 * Name of the Icon's Character.
	 */
	public var char:String = '';
	/**
	 * If the icon belongs to the Player or not.
	 */
	public var isPlayer:Bool = false;


	/**
	 * 
	 * @param char Character Name/Icon name.
	 * @param isPlayer If the icon should flip or not.
	 */
	public function new(char:String = 'bf', isPlayer:Bool = false) {
		super(0, 0);

		this.isPlayer = isPlayer;

		changeIcon(char);
		antialiasing = true;
		scrollFactor.set();

		bopScale = ClientPrefs.save.bopScale;
		lerpScale = ClientPrefs.save.lerpScale;
	}

	private var iconOffsets:Array<Float> = [0, 0];

	public function changeIcon(newChar:String):Void {
		if (newChar != char) {
			if (animation.getByName(newChar) == null) {
				var path = Paths.img('icons/icon-' + newChar);
				if (Assets.exists(Paths.img('icons/icon-' + newChar)))
					loadGraphic(path, true, 150, 150);
				else
					loadGraphic(Paths.image('icons/icon-face'), true, 150, 150);

				animation.add(newChar, [0, 1], 0, false, isPlayer);
				iconOffsets[0] = (width - 150) / 2;
				iconOffsets[1] = (width - 150) / 2;
				updateHitbox();
			}
			animation.play(newChar);
			char = newChar;
		}
	}

	/**
	 * The Scale the Icon should lerp to after bopping/scale changed.
	 */

	var lerpScale:Float = 1;

	/**
	 * The Amount of Steps it takes until the Icon Bops.
	 */

	var bopSteps:Int = 4;
	/**
	 * The Scale/Size the Icon should be every time it bops.
	 */
	var bopScale:Float = 1.2;


	/**
	 * The Step Hit function.
	 * Useful for allowing icons to bop earlier or later than a beat or whatever lolz.
	 * @param step Current Step.
	 */
	public function stepHit(step:Int = 0) {
		if (bopSteps < 1)
			bopSteps = 1;
		if (step % bopSteps == 0) {
			scale.set(bopScale, bopScale);
			updateHitbox();
		}
	}

	override function update(elapsed:Float) {
		var mult:Float = FlxMath.lerp(lerpScale, scale.x, Math.exp(-elapsed * 22));
		scale.set(mult, mult);
		updateHitbox();
		super.update(elapsed);

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 10, sprTracker.y - 30);
	}

	override function updateHitbox() {
		super.updateHitbox();
		offset.x = iconOffsets[0];
		offset.y = iconOffsets[1];
	}
}
