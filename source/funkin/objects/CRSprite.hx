package funkin.objects;

import flixel.system.FlxAssets.FlxGraphicAsset;

class CRSprite extends FlxSprite {
	public var name:String = "";
	public var zIndex:Int = 0; // used on gameplay, that's it.

	/**
	 * Contains an animation specific offsets.
	 */
	public var animOffsets:Map<String, Array<Float>> = [];

	public function new(nX:Float = 0, nY:Float = 0, ?nGraphic:FlxGraphicAsset) {
		super(nX, nY);
		if (nGraphic != null)
			loadGraphic(nGraphic);
	}

	/**
	 * A shortcut to `animation.addByPrefix`.
	 */
	public function addAnim(name:String, prefix:String, frameRate:Float = 30.0, looped:Bool = true, flipX:Bool = false, flipY:Bool = false) {
		animation.addByPrefix(name, prefix, frameRate, looped, flipX, flipY);
	}

	/**
	 * Sets XY scaling properties of this sprite equally.
	 * @param value The scaling value.
	 * @param noHitbox Whether to not update this sprite's hitbox
	 */
	public function setScale(value:Float, noHitbox:Bool = false) {
		scale.set(value, value);
		if (!noHitbox)
			updateHitbox();
	}

	/**
	 * Add a custom offset for specific animation.
	 * @param anim Your animation's name.
	 * @param offsetX The X offset.
	 * @param offsetY The Y offset.
	 */
	public function addOffset(anim:String, offsetX:Float, offsetY:Float) {
		animOffsets[anim] = [offsetX, offsetY];
	}

	/**
	 * A shortcut to `animation.play`, also applies custom offsets.
	 * @param animName Animation's name that will be played.
	 * @param force Whether to force the animation to play.
	 * @param reversed Whether to play the animation backwards.
	 * @param frame Whether to start the animation at specific frame.
	 */
	public function playAnim(animName:String, force:Bool = false, reversed:Bool = false, frame:Int = 0):Void {
		animation.play(animName, force, reversed, frame);

		if (animOffsets.exists(animName)) {
			var savedOffset = animOffsets.get(animName);
			var offsets:Dynamic = {
				x: flipX ? -savedOffset[0] : savedOffset[0],
				y: savedOffset[1]
			}

			var radians = angle * Math.PI / 180;
			offset.set(offsets.x * Math.cos(radians) - offsets.y * Math.sin(radians), offsets.x * Math.sin(radians) + offsets.y * Math.cos(radians));
		}
	}
}
