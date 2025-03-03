package;

import PsychFormat.AnimArray;
import dialogs.Dialogs;
import sys.io.File;
import PsychFormat;
import CharacterData;

using StringTools;

class CharConverter {
	static function main() {
		var result = Dialogs.open('Select Psych 0.7.3/1.03 Character File for Conversion.', [{ext: 'json', desc: ' Legacy Funkin\'\r // PSYCH 0.7.3 Format'},]);

		var legacyJSON:PsychFormat = cast haxe.Json.parse(File.read(result).readAll().toString().trim());
		Sys.println("\nConverting Character: " + result);

		var characterData:CharacterData = {
			name: "",
			flipX: legacyJSON.flip_x,
			texture_path: legacyJSON.image,
			health_icon: legacyJSON.healthicon,
			health_colors: legacyJSON.healthbar_colors,
			scale: legacyJSON.scale,
			singDuration: legacyJSON.sing_duration,

			camera_position: legacyJSON.camera_position,
			position: legacyJSON.position,
			antialiasing: (legacyJSON.no_antialiasing != null ? !legacyJSON.no_antialiasing : false),
			pixelated: false,

			animations: [],
			dancer: false // you may need to do it yourself as psych doesn't have this
		};

		for (anim in legacyJSON.animations) {
			var animation:AnimationData = {
				name: anim.anim,
				prefix: anim.name,
				fps: anim.fps,
				looped: anim.loop,
				x: anim.offsets[0],
				y: anim.offsets[1],
				indices: anim.indices,
			};
			characterData.animations.push(animation);
			trace("Converted Animation: " + anim.name);
		}




		var result2 = Dialogs.save('Save converted json', {ext: 'json', desc: 'JSON'});
		File.saveContent(result2, haxe.Json.stringify(characterData));
	}
}
