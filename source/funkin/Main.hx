package funkin;

import funkin.modding.PolymodHandler;
import funkin.backend.WeekData;
import funkin.debug.FPS;

class Main extends Sprite {
	public static var fpsCounter:FPS;
	public static var game:FlxGame;

	public function new() {
		super();

		game = new FlxGame(0, 0, funkin.states.Title);
		addChild(game);

		PolymodHandler.init(FLIXEL);
		ClientPrefs.load();

		FlxG.stage.frameRate = ClientPrefs.save.fps;
		FlxG.updateFramerate = ClientPrefs.save.fps;
		FlxG.drawFramerate = ClientPrefs.save.fps;
		
		WeekData.init();
		FlxG.mouse.load(Paths.image("cursor"), 0.5);

		fpsCounter = new FPS(10, 0, 0xFFFFFF);
		addChild(fpsCounter);
	}
}
