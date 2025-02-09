package funkin.objects;

import flixel.graphics.FlxGraphic;
import flixel.addons.display.FlxTiledSprite;

class Sustain extends FlxTiledSprite
{
	public static var originWidth:Float = 50;
	public static var scaleWidth:Float = originWidth * Note.noteScale;

	public static var tailOriginHeight:Float = 71;
	public static var tailScaleHeight:Float = tailOriginHeight * Note.noteScale;

	private var sustainUVData:Array<Array<Float>> = [
		[0, 0.125], // Left
		[0.25, 0.375], // Down
		[0.5, 0.625], // Up
		[0.75, 0.875], // Right
	];

	public var parent:Note = null;
	public var tailEnd:CRSprite = null;
	public var ay:Float = 0;

	public function new(parent:Note)
	{
		super(null, scaleWidth, 0, false, true);
		visible = true;
		this.parent = parent;
	

		tailEnd = new CRSprite();
	}

	public function init()
	{
		var prefix = parent.isPixel ? 'noteSkins/pixel/' : 'noteSkins/';
		var path = prefix + '${parent.texture}-sustains';

		if (!Assets.exists(Paths.image(path)))
			path = prefix + "notes-sustains";

		var graph = FlxGraphic.fromAssetKey(Paths.image(path));
		loadGraphic(graph);
		
		tailEnd.loadGraphic(graph, true, Std.int(graph.width / 8), graph.height);
		tailEnd.animation.add("idle", [
			switch (parent.data)
			{
				case 0:
					1;
				case 1:
					3;
				case 2:
					5;
				case 3:
					7;
				default:
					parent.data;
			}
		], 24);
		tailEnd.playAnim("idle");
		tailEnd.setGraphicSize(scaleWidth, tailScaleHeight);
		tailEnd.updateHitbox();

		// graphic.bitmap.disposeImage();
	}

	override function destroy()
	{
		if (tailEnd != null)
			tailEnd.destroy();
		super.destroy();
	}

	/**
	 * hi so uhh this code is awful
	 */
	var firstDraw:Bool = true;

	override function draw()
	{
		var receptor:StrumNote = parent.strum;
		if (receptor == null)
			return;
		var isDownscroll:Bool = parent.downscroll;
		// P = Parent // R = Receptor
		var sustainPos:
			{
				xP:Float,
				yP:Float,
				xR:Float,
				yR:Float
			} = {
				xP: parent.x + ((parent.width - width) * 0.5),
				yP: parent.y + (parent.height * 0.5),
				xR: receptor.x + ((parent.width - width) * 0.5),
				yR: receptor.y + (parent.height * 0.5),
			}
		var sustainHeight:Float = (parent.length * (parent.scrollSpeed * 1 * 0.45));

		x = sustainPos.xP;
		y = sustainPos.yP - (isDownscroll ? height : 0);
		alpha = parent.alpha * 0.7;

		width = scaleWidth;
		if (isDownscroll)
			ay = sustainPos.yP + parent.height / 2;
		var clip:Float = sustainHeight;
		if (parent.wasGoodHit)
		{
			// Clipping Effect //
			var lenDiff = (parent.length - (parent.conductor.songPosition - parent.time));
			clip = FlxMath.bound(lenDiff * (parent.scrollSpeed * 0.45), -tailScaleHeight, sustainHeight);
			height = Math.abs(clip);

			// Lock Position //
			var bound:{low:Null<Float>, high:Null<Float>} = {
				low: !isDownscroll ? sustainPos.yR : null,
				high: isDownscroll ? sustainPos.yR - height : null,
			}
			var value:Float = sustainPos.yP - (isDownscroll ? height : 0);
			y = FlxMath.bound(value, bound.low, bound.high);
			if (clip < 0)
			{
				y += isDownscroll ? height : -height;
				visible = false;
			}

			if (!isDownscroll)
				scrollY = sustainPos.yP - y;
		}
		else
		{
			height = sustainHeight;
		}

		if (visible)
		{
			cameras = parent.cameras;
			super.draw();
		}

		tailEnd.x = x;
		tailEnd.y = isDownscroll ? (clip > 0 ? y - tailEnd.height : y + height - tailEnd.height) : (clip > 0 ? y + height : y);
		tailEnd.flipY = isDownscroll;
		tailEnd.alpha = alpha;

		if (clip < 0)
		{
			var swagRect:FlxRect = tailEnd.clipRect;
			if (swagRect == null)
				swagRect = FlxRect.get(0, 0, isDownscroll ? tailEnd.frameWidth : tailEnd.width / tailEnd.scale.x, tailEnd.frameHeight);

			if (isDownscroll)
			{
				if (tailEnd.y + tailEnd.height >= sustainPos.yR)
				{
					swagRect.height = (sustainPos.yR - tailEnd.y) / tailEnd.scale.y;
					swagRect.y = tailEnd.frameHeight - swagRect.height;
				}
			}
			else
			{
				if (tailEnd.y <= sustainPos.yR)
				{
					swagRect.y = (sustainPos.yR - tailEnd.y) / tailEnd.scale.y;
					swagRect.height = (tailEnd.height / tailEnd.scale.y) - swagRect.y;
				}
			}
			tailEnd.clipRect = swagRect;
		}

		tailEnd.cameras = parent.cameras;
		tailEnd.draw();
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);
	}

	override function updateVerticesData():Void
	{
		if (graphic == null)
			return;

		graphicVisible = true;

		vertices[0] = vertices[6] = 0.0; // top left
		vertices[2] = vertices[4] = width; // top right

		vertices[1] = vertices[3] = 0.0; // bottom left
		vertices[5] = vertices[7] = height; // bottom right

		var frame:FlxFrame = graphic.imageFrame.frame;
		uvtData[0] = uvtData[6] = sustainUVData[parent.data][0];
		uvtData[2] = uvtData[4] = sustainUVData[parent.data][1];

		uvtData[1] = uvtData[3] = -scrollY / frame.sourceSize.y;
		uvtData[5] = uvtData[7] = uvtData[1] + height / frame.sourceSize.y;

		if (height <= 0)
			graphicVisible = false;
	}

	override function kill()
	{
		super.kill();
		tailEnd.kill();
	}

	public function setup(parent:Note):Sustain
	{
		this.parent = parent;
		graphic = null;
		revive();
		tailEnd.revive();
		init();

		return this;
	}
}
