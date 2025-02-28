package funkin.backend;

import haxe.Json;
import openfl.Assets;

using StringTools;

typedef SongData = {
	var song:String;
	var bpm:Float;
	var speed:Float;
	var sections:Array<Section>;

	var player1:String;
	var player2:String;
	var gfVersion:String;
	var stage:String;

	var skin:String;
}

typedef Section = {
	var bpm:Float;
	var changeBPM:Bool;
	var cameraFacePlayer:Bool;
	var notes:Array<Dynamic>;

	@:optional var lengthInSteps:Int;
	@:optional var events:Array<SwagEvent>;
	@:optional var altSection:Null<Bool>;
}

typedef SwagEvent = {
	var name:String;
	var time:Float;

	@:optional var val1:String;
	@:optional var val2:String;
}

class Song {
	public static inline function parseSong(songName:String = "high-school-conflict", diff:String = "normal") {
		diff = diff.toLowerCase();
		var song:SongData = cast Json.parse(Assets.getText(Paths.json('$songName/$diff')).trim().replace("\n", ""));

		return song;
	}

	public static function parseJSONshit(arg:Dynamic) {
		var song:SongData = cast Json.parse(arg);

		return song;
	}

	public static function dummy():SongData {
		return cast {
			song: "Bopeebo",
			bpm: 100.0,
			speed: 1.0,
			player1: "bf",
			player2: "dad",
			gfVersion: "gf",

			stage: "stage",
			skin: "",
			sections: []
		};
	}
}
