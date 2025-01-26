typedef SongData = {
	var song:String;
	var bpm:Float;
	var speed:Float;
	var sections:Array<Section>;
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
