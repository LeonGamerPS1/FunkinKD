typedef SongData =
{
	var song:String;
	var bpm:Float;
	var speed:Float;
	var sections:Array<Section>;

	var player1:String;
	var player2:String;
	var gfVersion:String;
	var stage:String;
}

typedef Section =
{
	var bpm:Float;
	var changeBPM:Bool;
	var cameraFacePlayer:Bool;
	var notes:Array<Dynamic>;
}

