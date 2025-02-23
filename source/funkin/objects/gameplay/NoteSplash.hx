package funkin.objects.gameplay;

import funkin.graphics.shaders.Pixel;
import flixel.addons.effects.FlxSkewedSprite;

class NoteSplash extends FlxSkewedSprite {
	static var gayray = ["left", "down", "up", "right"];

	public function new(id:Int = 0) {
		super();
		setup(id);
	}

	/**
	 * Called by PlayField.setupSplash.
	 * @param id  The NoteData of the Splash.
	 * @param strum The StrumNote the splash should Position itself to (if null, it will go to 0,0).
	 */
	public function setup(id:Int = 0, ?strum:StrumNote) {
		frames = Paths.getAtlas('splashes');
		animation.addByPrefix('splash', gayray[id], 24, false);
		animation.timeScale = FlxG.random.float(0.8, 1.2);
		setGraphicSize(width * 0.8);
		antialiasing = true;
		scale.set(FlxG.random.float(0.9, 1.2), FlxG.random.float(0.9, 1.2));
		angle = FlxG.random.float(-10.9, 20.2);
		updateHitbox();

		animation.play('splash', true);
		centerOffsets();
		centerOrigin();

		if (strum != null && strum.isPixel && shader == null)
			shader = new Pixel();
		if (strum != null)
			setPosition(strum.x, strum.y);

		return this;
	}

	override function update(elapsed:Float):Void {
		super.update(elapsed);
		if (animation.curAnim.finished)
			kill();
	}
}
