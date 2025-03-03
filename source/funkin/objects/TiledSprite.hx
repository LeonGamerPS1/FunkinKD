package funkin.objects;

import flixel.animation.FlxAnimation;
import flixel.graphics.tile.FlxDrawQuadsItem;
import flixel.animation.FlxAnimationController;

class TiledSprite extends OffsetSprite
{
	/**
	 * How many times the frame should repeat.
	 */
	public var tiles(default, set):Float;

	/**
	 * The tail gets it's own dedicated matrix transformation
	 * to ensure proper applications of frame-related properties
	 * such as offsets and rotations.
	 */
	var _tailMatrix:FlxMatrix = new FlxMatrix();

	var _tailFrame:FlxFrame;

	/**
	 * This variable holds a copy of the first or last tile's frame (depends on flipY).
	 * It is clipped to account for the decimal part of `tiles`.
	 * For example, this object would render 1 tile and a half when `tiles` equals `1.5`.
	 */
	var _clippedTileFrame:FlxFrame;

	/**
	 * When clipping a flipped frame, a gap would appear between the clipped and last rendered tile.
	 * This value is used to compensate for the gap by offsetting the position of the tile.
	 */
	var _clippingOffset:Float = 0;

	var _clippingDirty:Bool = false;
	var _quadAmount:Int = 0;

	/**
	 * Sets the tail frame for this sprite.
	 * @param animation Animation containing the desired tail frames. If `null`, no tail is rendered.
	 */
	public function setTail(animation:String):Void
	{
		if (animation == null)
		{
			_tailFrame = null;
			return;
		}

		var anim:FlxAnimation = this.animation.getByName(animation);

		if (anim == null)
		{
			FlxG.log.warn('TiledSprite: Could not find tail animation "${animation}"!');
			_tailFrame = null;
			return;
		}

		// copy the frame and modify coordinates to workaround texture bleeding gaps
		var frame:FlxFrame = frames.frames[anim.frames[0]];
		_tailFrame = frame.copyTo(_tailFrame);

	}

	@:inheritDoc(flixel.FlxSprite.getScreenBounds)
	override function getScreenBounds(?newRect:FlxRect, ?camera:FlxCamera):FlxRect
	{
		if (newRect == null)
			newRect = FlxRect.get();

		if (camera == null)
			camera = FlxG.camera;

		newRect.setPosition(x, y);
		if (pixelPerfectPosition)
			newRect.floor();

		_scaledOrigin.set(origin.x * scale.x, origin.y * scale.y);
		newRect.x += -Std.int(camera.scroll.x * scrollFactor.x) - offset.x + origin.x - _scaledOrigin.x;
		newRect.y += -Std.int(camera.scroll.y * scrollFactor.y) - offset.y + origin.y - _scaledOrigin.y;
		if (isPixelPerfectRender(camera))
			newRect.floor();

		// account for the sprite's height rather than the graphic's (fixes an issue where the sprite could prematurely be considered offscreen and stop rendering)
		newRect.setSize(frameWidth * Math.abs(scale.x), height);
		return newRect.getRotatedBounds(angle, _scaledOrigin, newRect);
	}

	override function draw():Void
	{
		if (_clippingDirty)
		{
			regenerateClippedFrame();
			_clippingDirty = false;
		}

		super.draw();
	}

	override function drawComplex(camera:FlxCamera):Void
	{
		getScreenPosition(_point, camera).subtractPoint(offset);
		_point.add(origin.x, origin.y);

		prepareMatrix(_frame, _matrix);
		prepareMatrix(_tailFrame, _tailMatrix);

		var drawItem:FlxDrawQuadsItem = camera.startQuadBatch(_frame.parent, true, true, blend, antialiasing, shader);
		var screenOffset:Float = (flipY ? tileHeight() : 0);

		for (i in getFirstTileOnScreen(camera)..._quadAmount)
		{
			drawTile(i, drawItem);

			// if it's offscreen, stop rendering
			if (_matrix.ty >= camera.viewMarginBottom + screenOffset)
			{
				break;
			}
		}
	}

	function drawTile(tile:Int, item:FlxDrawQuadsItem):Void
	{
		var frame:FlxFrame = _frame;
		var isTail:Bool = isTail(tile);

		if (isTileClipped(tile))
		{
			frame = _clippedTileFrame;
			if (_clippingOffset > 0)
			{
				matrixTranslate(-_clippingOffset);
			}
		}
		else if (isTail)
		{
			frame = _tailFrame;
		}

		item.addQuad(frame, isTail ? _tailMatrix : _matrix, colorTransform);
		matrixTranslate(frame.frame.height * Math.abs(scale.y));
	}

	function regenerateClippedFrame():Void
	{
		var parentFrame:FlxFrame = (_tailFrame != null && _quadAmount == 1) ? _tailFrame : _frame;
		var reduction:Float = parentFrame.frame.height * (_quadAmount - tiles);

		_clippedTileFrame = parentFrame.copyTo(_clippedTileFrame);
		_clippedTileFrame.frame.height -= reduction;
		_clippedTileFrame.frame.y += reduction;

		_clippingOffset = (flipY ? reduction * Math.abs(scale.y) : 0);
	}

	function prepareMatrix(frame:FlxFrame, matrix:FlxMatrix):Void
	{
		if (frame == null)
			return;

		frame.prepareMatrix(matrix, FlxFrameAngle.ANGLE_0, checkFlipX(), checkFlipY());

		matrix.translate(-origin.x, -origin.y);
		matrix.scale(scale.x, scale.y);

		if (bakedRotationAngle <= 0 && angle != 0)
			matrix.rotateWithTrig(_cosAngle, _sinAngle);

		matrix.translate(_point.x, _point.y);

		if (isPixelPerfectRender(camera))
		{
			matrix.tx = Math.floor(matrix.tx);
			matrix.ty = Math.floor(matrix.ty);
		}
	}

	function matrixTranslate(y:Float):Void
	{
		var translateX:Float = -y * _sinAngle;
		var translateY:Float = y * _cosAngle;

		if (_tailFrame != null)
			_tailMatrix.translate(translateX, translateY);

		_matrix.translate(translateX, translateY);
	}

	function getFirstTileOnScreen(camera:FlxCamera):Int
	{
		var offscreenHeight:Float = camera.viewMarginTop - _point.y;
		if (offscreenHeight <= 0)
			return 0;

		var nextTileHeight:Float = getHeightForTile(0);
		var output:Int = 0;

		while (offscreenHeight >= nextTileHeight)
		{
			matrixTranslate(nextTileHeight);
			offscreenHeight -= nextTileHeight;
			nextTileHeight = getHeightForTile(++output);
		}

		return output;
	}

	inline function isTileClipped(tile:Int):Bool
	{
		return (!flipY && tile == 0) || (flipY && tile == _quadAmount - 1);
	}

	inline function isTail(tile:Int):Bool
	{
		return _tailFrame != null && ((flipY && tile == 0) || (!flipY && tile == _quadAmount - 1));
	}

	inline function getHeightForTile(tile:Int):Float
	{
		return isTileClipped(tile) ? (_clippedTileFrame.frame.height * Math.abs(scale.y)) : (isTail(tile) ? tailHeight() : tileHeight());
	}

	inline function tileHeight():Float
	{
		return _frame.frame.height * Math.abs(scale.y);
	}

	inline function tailHeight():Float
	{
		return _tailFrame.frame.height * Math.abs(scale.y);
	}

	override function set_frame(v:FlxFrame):FlxFrame
	{
		var oldFrame:FlxFrame = frame;
		super.set_frame(v);

		if (v == null)
			return v;


		if (v != oldFrame)
		{
			_clippingDirty = true;
		}

		return v;
	}

	override function set_angle(v:Float):Float
	{
		super.set_angle(v);
		updateTrig();
		return v;
	}

	override function set_height(v:Float):Float
	{
		if (height != v)
		{
			tiles = v / tileHeight();
		}
		return super.set_height(v);
	}

	override function set_flipY(v:Bool):Bool
	{
		if (flipY != v)
		{
			_clippingDirty = true;
		}
		return super.set_flipY(v);
	}

	function set_tiles(v:Float):Float
	{
		if (tiles != v)
		{
			_quadAmount = Math.ceil(v);
			_clippingDirty = true;
		}
		return tiles = v;
	}

	override function destroy():Void
	{
		_clippedTileFrame = FlxDestroyUtil.destroy(_clippedTileFrame);
		_tailFrame = FlxDestroyUtil.destroy(_tailFrame);
		_tailMatrix = null;
		super.destroy();
	}
}

class OffsetSprite extends FlxSprite
{
	/**
	 * Animation offsets.
	 */
	public var offsets(default, null):OffsetMapper;

	/**
	 * Internal reference to the current animation offset.
	 */
	@:allow(funkin.objects.OffsetSprite)
	var _offsetPoint:FlxPoint;

	override function initVars():Void
	{
		// create the offset mapper before anything else.
		offsets = new OffsetMapper();

		super.initVars();

		// destroy the old animation controller as it contains few references, and create the custom one.
		animation.destroy();
		animation = new AnimationController(this);
	}

	// this method is used by FlxSprite's draw method to get the sprite's position on screen. we're overriding it so it accounts for animation offsets.
	override function getScreenPosition(?result:FlxPoint, ?camera:FlxCamera):FlxPoint
	{
		var output:FlxPoint = super.getScreenPosition(result, camera);

		if (_offsetPoint != null)
		{
			// also accounts for the angle property.
			output.subtract((_offsetPoint.x * _cosAngle) - (_offsetPoint.y * _sinAngle), (_offsetPoint.y * _cosAngle) + (_offsetPoint.x * _sinAngle));
		}

		return output;
	}

	/**
	 * Returns the screen position of this object without accounting for animation offsets.
	 * @param  result  Optional arg for the returning point
	 * @param  camera  The desired "screen" coordinate space. If `null`, `FlxG.camera` is used.
	 * @return The screen position of this object.
	 */
	public function getScreenCoords(?result:FlxPoint, ?camera:FlxCamera):FlxPoint
	{
		return super.getScreenPosition(result, camera);
	}

	/**
	 * Plays an existing animation. If you call an animation that is already playing, it will be ignored.
	 * @param name The string name of the animation you want to play.
	 * @param force Whether to force the animation to restart.
	 * @param reversed Whether to play animation backwards or not.
	 * @param frame The frame number in the animation you want to start from. If a negative value is passed, a random frame is used
	 */
	public function playAnimation(name:String, force:Bool = false, reversed:Bool = false, frame:Int = 0):Void
	{
		animation.play(name, force, reversed, frame);
	}

	/**
	 * Clean up memory.
	 */
	override public function destroy():Void
	{
		if (offsets != null)
		{
			offsets.clear();
			offsets = null;
		}

		_offsetPoint = null;
		super.destroy();
	}
}

/**
 * Custom animation controller, made to apply animation offsets when calling `play`.
 */
private class AnimationController extends FlxAnimationController
{
	var _parent:OffsetSprite;

	public function new(parent:OffsetSprite):Void
	{
		super(parent);
		_parent = parent;
	}

	override function play(animation:String, force:Bool = false, reversed:Bool = false, frame:Int = 0):Void
	{
		super.play(animation, force, reversed, frame);
		@:privateAccess
		_parent._offsetPoint = _parent.offsets.get(animation);
	}

	override function rename(oldName:String, newName:String):Void
	{
		super.rename(oldName, newName);

		// ensure animation offsets are renamed
		var offsets:FlxPoint = _parent.offsets.get(oldName);
		if (offsets != null)
		{
			_parent.offsets.removeUnsafe(oldName);
			_parent.offsets.addPoint(newName, offsets);
		}
	}

	override function destroy():Void
	{
		_parent = null;
		super.destroy();
	}
}

/**
 * Simple interface to manipulate offsets.
 */
private abstract OffsetMapper(Map<String, FlxPoint>)
{
	public function new():Void
	{
		this = [];
	}

	/**
	 * Adds an animation offset.
	 * @param animation The animation in which the offset will be applied to.
	 * @param x Horizontal offset value.
	 * @param y Vertical offset value.
	 */
	public function add(animation:String, x:Float = 0, y:Float = 0):Void
	{
		addPoint(animation, FlxPoint.get(x, y));
	}

	/**
	 * Adds an `FlxPoint` as animation offset.
	 * @param animation The animation in which the offset will be applied to.
	 * @param point The offset point.
	 */
	public function addPoint(animation:String, point:FlxPoint):Void
	{
		this.set(animation, point);
	}

	/**
	 * Returns the corresponding offset point for the passed animation if it exists, `null` otherwise.
	 * @param animation The animation to find the offsets for.
	 */
	public function get(animation:String):FlxPoint
	{
		return this.get(animation);
	}

	/**
	 * Returns `true` if an offset point exists for the passed animation, `false` otherwise.
	 * @param animation The animation to check
	 */
	public function exists(animation:String):Bool
	{
		return this.exists(animation);
	}

	/**
	 * Removes the animation offsets for the passed animation if it exists.
	 * @param animation The animation to remove it's offsets for.
	 * @return `true` if the offset point has been found and removed, `false` otherwise.
	 */
	public function remove(animation:String):Bool
	{
		this.get(animation)?.put();
		return this.remove(animation);
	}

	/**
	 * Removes the animation offsets from the given animation without putting the underlying `FlxPoint` back into the point pool.
	 * @param animation The animation.
	 * @return Bool
	 */
	public function removeUnsafe(animation:String):Bool
	{
		return this.remove(animation);
	}

	/**
	 * Removes all of the stored animation offsets.
	 */
	public function clear():Void
	{
		for (key in this.keys())
			remove(key);
	}

	/**
	 * Returns a list of animations which got offsets.
	 */
	public function list():Array<String>
	{
		return [for (key in this.keys()) key];
	}
}
