package funkin.objects;

import flixel.graphics.FlxGraphic;

class Sustain extends TiledSprite {
	var parent:Note;

	public function new(parent:Note) {
		super(0, 0);
		this.parent = parent;

		init();
	}

	function init() {
		if (parent.isPixel)
			pixel();
		else
			normal();
	}

	function pixel() {
		var tex = parent.texture;
		var data = parent.data;

		var graphic:FlxGraphic = Paths.image('noteSkins/pixel/${tex}ENDS');

		loadGraphic(graphic, true, Math.floor(graphic.width / 4), Math.floor(graphic.height / 2));

		animation.add('hold', [data], 12, false);
		animation.add('end', [data + 4], 12, false);
		playAnimation("hold");
		updateHitbox();

		setGraphicSize(width * 6);
		setTail('end');
		updateHitbox();
	}

	function normal() {
		frames = parent.frames;
		animation.copyFrom(parent.animation);

		playAnimation('hold');
		setTail('end');
		updateHitbox();

		setGraphicSize(width * 0.7);
		updateHitbox();

		antialiasing = true;
	}

	static public var colArray:Array<FlxColor> = [FlxColor.PURPLE, FlxColor.BLUE, FlxColor.GREEN, FlxColor.RED];

	override function draw() {
		var length:Float = parent.length;
		if (shader != parent.shader)
			shader = parent.shader;

		if (parent.wasGoodHit && !parent.inEditor)
			length -= parent.conductor.songPosition - parent.time;

		var expectedHeight:Float = (length * 0.45 * parent.scrollSpeed);
		this.height = Math.max(expectedHeight, 0);

		setPosition(parent.x + ((parent.width - width) * 0.5), parent.y + (Note.swagWidth * 0.5));

		y = parent.y + parent.height * 0.5;
		alpha = parent.alpha * 0.7;

		if (parent.downscroll) {
			y -= height;
			flipY = true;
		} else {
			flipY = false;
		}

		super.draw();
	}
}
