package funkin.backend;

import flixel.FlxBasic;
import flixel.util.FlxSignal;

class Conductor extends FlxBasic {
	public var songPosition:Float = 0;
	public var bpm(default, set):Float = 100;
	public var beatLength:Float;
	public var stepLength:Float;

	public var curBeat:Int = 0;
	public var curStep:Int = 0;
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

	function set_bpm(value:Null<Float>):Null<Float> {
		bpm = value;
		beatLength = (60 / bpm) * 1000;
		stepLength = beatLength / 4;

		return bpm = value;
	}

	private inline function updateStep() {
		curStep = Math.floor(songPosition / stepLength);
	}

	private inline function updateBeat() {
		curBeat = Math.floor(curStep / 4);
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
