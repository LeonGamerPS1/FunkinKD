package funkin;

import haxe.ui.Toolkit;
import funkin.modding.PolymodHandler;
import funkin.backend.WeekData;
import funkin.debug.FPS;

class Main extends Sprite
{
	public function new()
	{
		super();
		addChild(new FlxGame(0, 0, funkin.states.Title, 140, 140));
	

		PolymodHandler.init(FLIXEL);
		ClientPrefs.load();
		Toolkit.init();
		WeekData.init();
		FlxG.mouse.load(Paths.image("cursor"), 0.5);

		var fpsVar:FPS = cast addChild(new FPS(10, 0, 0xFFFFFF));
	}
}
