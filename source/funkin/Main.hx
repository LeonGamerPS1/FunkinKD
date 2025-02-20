package funkin;

import funkin.modding.PolymodHandler;
import funkin.backend.WeekData;
import funkin.debug.FPS;

class Main extends Sprite
{
	public function new()
	{
		super();
		addChild(new FlxGame(0, 0, funkin.states.Title));

		PolymodHandler.init(FLIXEL);
		ClientPrefs.load();

		WeekData.init();
		FlxG.mouse.load(Paths.image("cursor"), 0.5);

		var fpsVar:FPS = cast addChild(new FPS(10, 0, 0xFFFFFF));
	}
}
