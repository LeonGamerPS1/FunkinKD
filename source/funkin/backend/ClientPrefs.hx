package funkin.backend;

import lime.app.Application;

@:structInit
class SaveVars {
	/* 
		Wether the game should have the notes scroll down or not.
	 */
	public var downScroll:Bool = false;

	/**
	 * Low Quality Mode allows for better performance if some stage elements seem to be laggy
	 */
	public var lowQuality:Bool = true;

	/** If the players notes should be in the middle and opponent strums hidden.**/
	public var middleScroll:Bool = false;

	/** 
	 * The Scale the icons should lerp to.
	* **/
	public var lerpScale:Float = 1;

	/** 
	 * The Scale the icons should be when bopping.
	* **/
	public var bopScale:Float = 1.2;

	/**
	 * The FPS the game should run at.
	 */
	public var fps:Int = 64;

	public var sickWindow:Float = 45;
	public var goodWindow:Float = 90;
	public var badWindow:Float = 135;

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

		// saves data on app close
		Application.current.onExit.add(function(?errCode:Int = 0) {
			saveToFlixel();
		}, false, 1);
	}

	// Saves the Options/Prefs to FlxG.save.data to load at game startup.
	public static function saveToFlixel() {
		for (saveElement in Reflect.fields(save))
			Reflect.setProperty(FlxG.save.data, saveElement, Reflect.getProperty(saveElement, saveElement));
	}
}
