package funkin.backend;

import lime.app.Application;

@:structInit
class SaveVars
{
	public var downScroll:Bool = false;
	public var lowQuality:Bool = true;

	public var middleScroll:Bool = false;
	public var disableCharacters:Bool = false;
	public var iconScale:Float = 1.2;

	public var arrowRGB:Array<Array<FlxColor>> = [
		[0xFFC24B99, 0xFFFFFFFF, 0xFF3C1F56],
		[0xFF00FFFF, 0xFFFFFFFF, 0xFF1542B7],
		[0xFF12FA05, 0xFFFFFFFF, 0xFF0A4447],
		[0xFFF9393F, 0xFFFFFFFF, 0xFF651038]
	];
	public var arrowRGBPixel:Array<Array<FlxColor>> = [
		[0xFFE276FF, 0xFFFFF9FF, 0xFF60008D],
		[0xFF3DCAFF, 0xFFF4FFFF, 0xFF003060],
		[0xFF71E300, 0xFFF6FFE6, 0xFF003100],
		[0xFFFF884E, 0xFFFFFAF5, 0xFF6C0000]
	];

	public function new()
	{
	}
}

class ClientPrefs
{
	// Variable to store the saved preferences
	public static var save:SaveVars;

	// Variable to store the default preferences
	public static var def:SaveVars;

	// Function to load the saved preferences
	public static function load()
	{
		def = new SaveVars();
		if (FlxG.save.data.save != null)
			save = FlxG.save.data.save;
		else
			save = new SaveVars();
		saveToFlixel();
		Application.current.onExit.add(function(?errCode:Int = 0)
		{
			saveToFlixel();
		}, false, 1);
	}

	public static function saveToFlixel()
	{
		for (yes in Reflect.fields(save))
			Reflect.setProperty(FlxG.save.data, yes, Reflect.getProperty(save, yes));
	}
}
