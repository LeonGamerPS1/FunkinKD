package funkin.modding.scripting;


import funkin.objects.Alphabet;
import funkin.objects.Character;
import openfl.utils.Assets;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.FlxG;
import hscript.Parser;
import hscript.Interp;

class HScriptRuntime
{
	public static var parser:crowplexus.hscript.Parser = new crowplexus.hscript.Parser();

	public var interp:crowplexus.hscript.Interp;

	/**
	 * The scripts name. Useful for preventing scripts with the same names from being loaded.
	 */
	public var scriptName:String = "_script";

	public function get_variables()
	{
		return interp.variables;
	}

	public function new(path:String)
	{
		scriptName = path;

		interp = new crowplexus.hscript.Interp();
		interp.variables.set('FlxG', FlxG);
		interp.variables.set('FlxSprite', FlxSprite);
		interp.variables.set('FlxCamera', FlxCamera);
		interp.variables.set('FlxTimer', FlxTimer);
		interp.variables.set('FlxTween', FlxTween);
		interp.variables.set('FlxEase', FlxEase);
		interp.variables.set('PlayState', PlayState);
		interp.variables.set('game', PlayState.instance);
		interp.variables.set('Paths', Paths);
		interp.variables.set('Conductor', Conductor);
		interp.variables.set('ClientPrefs', ClientPrefs);
		interp.variables.set('Character', Character);
		interp.variables.set('Alphabet', Alphabet);
		interp.variables.set('ShaderFilter', openfl.filters.ShaderFilter);
		interp.variables.set('StringTools', StringTools);
		interp.variables.set('math', MathWrapper);
        execute(Assets.getText(path));
		trace("loaded script: " + '"$path"');

	}

	public function call(name:String, ?args:Array<Any>)
	{
		args ??= [];
		var func = interp.variables.get(name);
		var obj = {func: func};
		if (func != null)
			Reflect.callMethod(obj, obj.func, args);
	}

	public function set(field:String, value:Dynamic)
	{
		interp.variables.set(field, value);
	}

	public function execute(codeToRun:String):Dynamic
	{
		@:privateAccess
		parser.line = 1;
		parser.allowTypes = true;
		parser.resumeErrors = true;
		parser.allowJSON = true;
		parser.allowMetadata = true;

		return interp.execute(parser.parseString(codeToRun));
	}
}
