package funkin.states;

import flixel.FlxG;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.sound.FlxSound;
import funkin.backend.Conductor;
import funkin.backend.Song;
import funkin.objects.Note;
import funkin.objects.StrumNote;

class PlayState extends FlxState {
	public var oppStrums:FlxTypedSpriteGroup<StrumNote> = new FlxTypedSpriteGroup(50, 50);
	public var playerStrums:FlxTypedSpriteGroup<StrumNote> = new FlxTypedSpriteGroup(FlxG.width / 2 + (160 * 0.7), 50);
	public var conductor:Conductor;

	public static var SONG:SongData;

	public var inst:FlxSound;

	override public function create() {
		if (SONG == null)
			SONG = Song.parseSong();

		conductor = new Conductor(SONG.bpm);
		add(conductor);

		super.create();
		for (i in 0...4) {
			var strumNote:StrumNote = new StrumNote(i);
			strumNote.x += (160 * 0.7) * i;
			oppStrums.add(strumNote);
		}
		for (i in 0...4) {
			var strumNote:StrumNote = new StrumNote(i);
			strumNote.x += (160 * 0.7) * i;
			playerStrums.add(strumNote);
		}
		add(oppStrums);
		add(playerStrums);
		conductor.onBeatHit.add(function() {
			trace(conductor.curBeat);
		});
		inst = new FlxSound();
		inst.loadEmbedded(Paths.inst(SONG.song));
		FlxG.sound.list.add(inst);
		inst.time = -conductor.beatLength * 4;
		add(new Note(0));
	}

	override public function update(elapsed:Float) {
		conductor.songPosition = inst.time;
		super.update(elapsed);
		keyPress();
	}

	function keyPress() {
		var keyP:Array<Bool> = [
			FlxG.keys.justPressed.LEFT,
			FlxG.keys.justPressed.DOWN,
			FlxG.keys.justPressed.UP,
			FlxG.keys.justPressed.RIGHT
		];
		var keyR:Array<Bool> = [
			FlxG.keys.justReleased.LEFT,
			FlxG.keys.justReleased.DOWN,
			FlxG.keys.justReleased.UP,
			FlxG.keys.justReleased.RIGHT
		];
		playerStrums.forEach(function(strumNote) {
			if (keyP[strumNote.data])
				strumNote.playAnim("confirm", true);
			if (keyR[strumNote.data])
				strumNote.playAnim("static");
		});
	}
}
