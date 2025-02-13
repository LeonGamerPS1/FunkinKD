package funkin;

#if MOD import funkin.modding.PolymodHandler; #end
import funkin.backend.WeekData;
import funkin.debug.FPS;

class Main extends Sprite
{
	public function new()
	{
		super();
		addChild(new FlxGame(0, 0, funkin.states.Title));

		#if MOD PolymodHandler.init(FLIXEL);#end
		ClientPrefs.load();

		WeekData.init();
		FlxG.mouse.load(Paths.image("cursor"), 0.5);

		var fpsVar:FPS = cast addChild(new FPS(10, 0, 0xFFFFFF));
	}
}
