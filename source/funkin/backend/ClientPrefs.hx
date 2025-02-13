package funkin.backend;

import lime.app.Application;

@:structInit
class SaveVars {
	public var downScroll:Bool = false;
	public var lowQuality:Bool = true;

    public var middleScroll:Bool = false;
    public var disableCharacters:Bool = false;

	public var iconScale:Float = 1.2;

	public function new() {}
}

class ClientPrefs {
	// Variable to store the saved preferences
	public static var save:SaveVars;

	// Variable to store the default preferences
	public static var def:SaveVars;

	// Function to load the saved preferences
	public static function load() {
		def = new SaveVars();
		if (FlxG.save.data.save != null)
			save = FlxG.save.data.save;
		else
			save = new SaveVars();
		saveToFlixel();
        Application.current.onExit.add(function(?errCode:Int = 0) {
            saveToFlixel();
        },false,1);
	}

	public static function saveToFlixel() {
		for (yes in Reflect.fields(save))
			Reflect.setProperty(FlxG.save.data, yes, Reflect.getProperty(save, yes));
	}
}
