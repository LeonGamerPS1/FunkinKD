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
	var skin:String; // skin for strumlines n' notes
}

typedef Section = {
	var bpm:Float;
	var changeBPM:Bool;
	var cameraFacePlayer:Bool;
	var notes:Array<ChartNote>;
}

typedef ChartNote = {
	var time:Float;
	var noteData:Int;
	var length:Float;
}


class Song {
	public static inline function parseSong(songName:String = "high-school-conflict", diff:String = "normal") {
		var song:SongData = cast Json.parse(Assets.getText(Paths.json('$songName/$diff')).trim().replace("\n", ""));

		return song;
	}
}
