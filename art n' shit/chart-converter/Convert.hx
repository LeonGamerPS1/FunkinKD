package;

import dialogs.Dialogs;
import SongData;
import sys.io.File;

using StringTools;

class Convert {
	static function main() {
		var result = Dialogs.open('Select LEGACY FNF/PSYCH 0.7.3 JSON For conversion.', [{ext: 'json', desc: ' Legacy Funkin\'\r // PSYCH 0.7.3 Format'},]);

		var legacyJSON:SwagSong =  cast haxe.Json.parse(File.read(result).readAll().toString().trim()).song;
		Sys.println("\nConverting SONG: " + legacyJSON.song + "\nDiff: " + getDiff(result));
		var uhm:SongData = {
			song: legacyJSON.song,
			speed: legacyJSON.speed,
			bpm: legacyJSON.bpm,
			player1:legacyJSON.player1,
			player2:legacyJSON.player2,
		    gfVersion:legacyJSON.gfVersion,
			sections: [],
			stage: Reflect.getProperty(legacyJSON,"stage")
		};
     for(section in legacyJSON.notes)
      {
		var sectionB:Section = {
			bpm:section.bpm,
			changeBPM:section.changeBPM,
			cameraFacePlayer:section.mustHitSection,
	        notes:[],
		}
		for(sectionNote in section.sectionNotes)
		{
          var time:Float = sectionNote[0];
		  var mustHit:Bool = section.mustHitSection;
		  var length:Float = sectionNote[2] is String ? 0 : sectionNote[2];
		  if(sectionNote[1] > 3)
			mustHit = !section.mustHitSection;
		  var data:Int = Std.int(sectionNote[1] % 4);
		  if(mustHit)
			data += 4;
		  sectionB.notes.push({time:time,noteData:data,length:length});
		}
           uhm.sections.push(sectionB);
	  }
	  trace(uhm.sections.length);
	  result = Dialogs.save('Save converted json',
            { ext:'json', desc:'JSON' }
      );
	 File.saveContent(result,haxe.Json.stringify(uhm));
	}

	static function getDiff(name:String = "bopeebo-hard") {
		return name.split("-")[name.split("-").length - 1].replace(".json", "");
	}
}
