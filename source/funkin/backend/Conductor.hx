package funkin.backend;

import flixel.FlxBasic;
import flixel.util.FlxSignal;

typedef BPMChangeEvent = {
	var stepTime:Int;
	var songTime:Float;
	var bpm:Float;
}

class Conductor extends FlxBasic {
	public var songPosition:Float = 0;
	public var bpm(default, set):Float = 100;
	public var beatLength:Float;
	public var stepLength:Float;

	public var bpmChangeMap:Array<BPMChangeEvent> = [];

	public var curBeat:Int = 0;
	public var curStep:Int = 0;

	public var curStepDec:Float = 0;
	public var curBeatDec:Float = 0;

	public var lastBeat:Int = 0;
	public var lastStep:Int = 0;

	public var onBeatHit:FlxSignal;
	public var onStepHit:FlxSignal;

	public static var safeFrames:Int = 10;
	public static var safeZoneOffset:Float = (safeFrames / 60) * 1000; // is calculated in create(), is safeFrames in milliseconds

	public function new(bpm:Float = 100) {
		super();
		this.bpm = bpm;
		songPosition = 0;

		onBeatHit = new FlxSignal();
		onStepHit = new FlxSignal();

		onStepHit.add(function() {
			if (curStep % 4 == 0)
				onBeatHit.dispatch();
		});
	}

	public function mapBPMChanges(song:SongData) {
		bpmChangeMap = [];

		var curBPM:Float = song.bpm;
		var totalSteps:Int = 0;
		var totalPos:Float = 0;
		for (i in 0...song.sections.length)
		{
			if(song.sections[i].changeBPM && song.sections[i].bpm != curBPM)
			{
				curBPM = song.sections[i].bpm;
				var event:BPMChangeEvent = {
					stepTime: totalSteps,
					songTime: totalPos,
					bpm: curBPM
				};
				bpmChangeMap.push(event);
			}

			var deltaSteps:Int = 16;
			totalSteps += deltaSteps;
			totalPos += ((60 / curBPM) * 1000 / 4) * deltaSteps;
		}
	}

	function set_bpm(value:Null<Float>):Null<Float> {
		bpm = value;
		beatLength = (60 / bpm) * 1000;
		stepLength = beatLength / 4;

		return bpm = value;
	}

	private inline function updateStep() {
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}
		for (i in 0...bpmChangeMap.length)
		{
			if (songPosition >= bpmChangeMap[i].songTime)
				lastChange = bpmChangeMap[i];
		}

		curStep = lastChange.stepTime +  Math.floor(songPosition / stepLength);
		curStepDec = (songPosition / 1000)*(bpm * 4/60);
	}

	private inline function updateBeat() {
		curBeat = Math.floor(curStep / 4);
		curBeatDec = curStepDec / 4;
	}

	override function update(elapsed:Float) {
		lastStep = curStep;
		lastBeat = curStep;
		updateStep();
		updateBeat();

		if (lastStep != curStep)
			onStepHit.dispatch();
	}
}
