package funkin;

import funkin.debug.FPS;

class Main extends Sprite {
	public function new() {
		super();
		addChild(new FlxGame(0, 0, funkin.states.PlayState));
		addChild(new FPS(10, 0, 0xFFFFFF));
	}
}
