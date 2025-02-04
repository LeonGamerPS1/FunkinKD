package funkin.objects;

class HealthIcon extends FlxSprite
{
	/**
	 * Used for FreeplayState! If you use it elsewhere, prob gonna annoying
	 */
	public var sprTracker:FlxSprite;

	public var char:String = '';
	public var isPlayer:Bool = false;

	public function new(char:String = 'bf', isPlayer:Bool = false)
	{
		super(0, 0);

		this.isPlayer = isPlayer;

		changeIcon(char);
		antialiasing = true;
		scrollFactor.set();
	}

	private var iconOffsets:Array<Float> = [0, 0];

	public function changeIcon(newChar:String):Void
	{
		if (newChar != char)
		{
			if (animation.getByName(newChar) == null)
			{
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

	var lerpScale:Float = 1;
	var bopSteps:Int = 4;

	public function stepHit(step:Int = 0)
	{
		if (bopSteps < 1)
			bopSteps = 1;
		if (step % bopSteps == 0) {
			scale.set(1.2, 1.2);
			updateHitbox();
		}
	}

	override function update(elapsed:Float)
	{
		var mult:Float = FlxMath.lerp(lerpScale, scale.x, Math.exp(-elapsed * 16));
		scale.set(mult, mult);
		updateHitbox();
		super.update(elapsed);

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 10, sprTracker.y - 30);
	}

	override function updateHitbox()
	{
		super.updateHitbox();
		offset.x = iconOffsets[0];
		offset.y = iconOffsets[1];
	}
}
