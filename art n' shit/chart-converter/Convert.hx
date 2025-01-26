package;

import dialogs.Dialogs;
import sys.io.File;

using StringTools;

class Convert {
	static function main() {
		var result = Dialogs.open('Select LEGACY FNF/PSYCH 0.7.3 JSON For conversion.', [{ext: 'json', desc: ' Legacy Funkin\'\r // PSYCH 0.7.3 Format'},]);

		var legacyJSON:SwagSong = cast haxe.Json.parse(File.read(result).readAll().toString().trim()).song;
		Sys.println("\nConverting SONG: " + legacyJSON.song + "\nDiff: " + getDiff(result));
	}

	static function getDiff(name:String = "bopeebo-hard") {
		return name.split("-")[name.split("-").length - 1].replace("json", "");
	}
}
