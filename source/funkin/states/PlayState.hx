package funkin.states;

import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
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

	public var unspawnNotes:Array<Note> = [];
	public var notes:FlxTypedGroup<Note> = new FlxTypedGroup();

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
		genSong(SONG.sections);

		add(notes);

		inst = new FlxSound();
		inst.loadEmbedded(Paths.inst(SONG.song));
		FlxG.sound.list.add(inst);
		inst.time = -conductor.beatLength * 4;
		inst.play();
	}

	function genSong(sections:Array<Section>) {
		for (i in 0...sections.length) {
			for (ii in 0...sections[i].notes.length) {
				var time:Float = sections[i].notes[ii].time;
				var goodHit:Bool = sections[i].notes[ii].noteData > 3;
				var data:Int = sections[i].notes[ii].noteData % 4;
				var note:Note = new Note(time, data, false);
				note.mustHit = goodHit;

				unspawnNotes.push(note);
			}
		}
		unspawnNotes.sort(function(n1, n2) {
			return Std.int(n1.time - n2.time);
		});
	}

	override public function update(elapsed:Float) {
		conductor.songPosition = inst.time;
		for (index => value in unspawnNotes) {
			if (value.time - conductor.songPosition > 1600 / SONG.speed) {
				unspawnNotes.remove(value);
				unspawnNotes.sort(function(n1, n2) {
					return Std.int(n1.time - n2.time);
				});
				notes.add(value);
			}
		}
		notes.forEach(function(note) {
			var strumGroup = note.mustHit ? playerStrums : oppStrums;
			var strum:StrumNote = strumGroup.members[note.data];

			if (note.x != strum.x)
				note.x = strum.x;

			note.y = strum.y + (note.time - conductor.songPosition) * 0.45 * SONG.speed;

			if (!note.mustHit && note.canBeHit(conductor)) {
				strum.playAnim("confirm", true);
				strum.resetTimer = 200 / 1000;
				destroyNote(note);
			}
		});
		super.update(elapsed);
		keyPress();
	}

	function destroyNote(note:Note) {
		note.kill();
		notes.remove(note, true);
		note.destroy();
		note = null;
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
