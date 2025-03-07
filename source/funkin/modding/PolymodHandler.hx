package funkin.modding;

import funkin.backend.WeekData;
import funkin.backend.FileUtil;
import polymod.Polymod;
import polymod.format.ParseRules.TextFileFormat;
import polymod.fs.ZipFileSystem;

class PolymodHandler
{
	static final MOD_FOLDER:String =
		#if (REDIRECT_ASSETS_FOLDER && macos)
		'../../../../../../../example_mods'
		#elseif REDIRECT_ASSETS_FOLDER
		'../../../../example_mods'
		#else
		'mods'
		#end;

	static final CORE_FOLDER:Null<String> =
		#if (REDIRECT_ASSETS_FOLDER && macos)
		'../../../../../../../assets'
		#elseif REDIRECT_ASSETS_FOLDER
		'../../../../assets'
		#else
		null
		#end;

	public static var loadedMods:Array<ModMetadata> = [];

	// Use SysZipFileSystem on desktop and MemoryZipFilesystem on web.
	static var modFileSystem:Null<ZipFileSystem> = null;

	public static function init(?framework:Null<Framework>)
	{
		#if (!android)
		#if sys // fix for crash on sys platforms
		if (!sys.FileSystem.exists('./mods'))
			sys.FileSystem.createDirectory('./mods');
		#end
		var dirs:Array<String> = [];
		var polyMods = Polymod.scan({modRoot: './mods/'});
		for (i in 0...polyMods.length)
		{
			var value = polyMods[i];
			dirs.push(value.modPath.split("./mods/")[1]);
			loadedMods.push(value);
		}
		framework ??= FLIXEL;

		Polymod.init({
			framework: FLIXEL,
			modRoot: "./mods/",
			dirs: dirs,
			parseRules: buildParseRules(),
			errorCallback: PolymodErrorHandler.error
		});
		Polymod.registerAllScriptClasses();
	
		// forceReloadAssets();
		#end
	}

	public static function createModRoot():Void
	{
		FileUtil.createDirIfNotExists(MOD_FOLDER);
	}

	static function buildParseRules():polymod.format.ParseRules
	{
		var output:polymod.format.ParseRules = polymod.format.ParseRules.getDefault();
		// Ensure TXT files have merge support.
		output.addType('txt', TextFileFormat.LINES);
		output.addType('json', TextFileFormat.JSON);
		// Ensure script files have merge support.
		output.addType('hscript', TextFileFormat.PLAINTEXT);
		output.addType('hxs', TextFileFormat.PLAINTEXT);
		output.addType('hxc', TextFileFormat.PLAINTEXT);
		output.addType('hx', TextFileFormat.PLAINTEXT);

		return output;
	}

	public static function forceReloadAssets():Void
	{
		for (i in 0...loadedMods.length)
		{
			var mod = loadedMods[i];
			mod = null;
			loadedMods.remove(mod);
		}
		loadedMods = [];
		WeekData.reload();
		Polymod.clearScripts();
		Polymod.registerAllScriptClasses();
		Polymod.reload();
		init(FLIXEL);
	}
}
