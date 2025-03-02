package funkin.objects;

import flixel.graphics.FlxGraphic;

class ChartSustain extends TiledSprite {
	var parent:Note;

	public function new(parent:Note, gridBG:FlxSprite, daSus:Float = 0) {
		super();

		this.parent = parent;
		if (parent.isPixel)
			pixel();
		else
			normal();

		setGraphicSize(width = parent.width / 3);
		updateHitbox();
		height = FlxMath.remapToRange(daSus, 0, parent.conductor.stepLength * 16, 0, gridBG.height);
		shader = parent.shader;

		setPosition(parent.x + ((parent.width - width) * 0.5), parent.y + (parent.height * 0.5));
	}

	function pixel() {
		var tex = parent.texture;
		var data = parent.data;
		trace(tex);

		var graphic:FlxGraphic = Paths.image('noteSkins/pixel/${tex}ENDS');
		loadGraphic(graphic, true, Math.floor(graphic.width / 4), Math.floor(graphic.height / 2));

		animation.add('hold', [data], 12, false);
		animation.add('end', [data + 4], 12, false);
		playAnimation("hold");
		
		setGraphicSize(width * 6);
		updateHitbox();
		setTail('end');
	}

	function normal() {
		frames = parent.frames;
		animation.copyFrom(parent.animation);

		playAnimation('hold');
		setGraphicSize(width * 0.7);
		updateHitbox();
		setTail('end');

		antialiasing = true;
	}
}
