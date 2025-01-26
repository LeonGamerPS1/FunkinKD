package funkin.states;

import flixel.math.FlxMath;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.sound.FlxSound;
import flixel.util.FlxSort;
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
	public var ds:Bool = false;
	public var noteKillOffset:Float = 350;

	public var camUnderlay:FlxCamera;
	public var camHUD:FlxCamera;

	override public function create() {
		if (SONG == null)
			SONG = Song.parseSong();

		camHUD = new FlxCamera();
		camUnderlay = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camUnderlay.bgColor.alpha = 0;
		FlxG.cameras.add(camUnderlay, false);
		FlxG.cameras.add(camHUD, false);

		conductor = new Conductor(SONG.bpm);
		conductor.bpm = SONG.bpm;
		add(conductor);

		uiGroup.cameras = [camHUD];

		super.create();
		for (i in 0...4) {
			var strumNote:StrumNote = new StrumNote(i);
			strumNote.downScroll = ds;
			strumNote.x += (160 * 0.7) * i;
			oppStrums.add(strumNote);
		}
		for (i in 0...4) {
			var strumNote:StrumNote = new StrumNote(i);
			strumNote.x += (160 * 0.7) * i;
			strumNote.downScroll = ds;
			playerStrums.add(strumNote);
		}
		if (ds)
			for (strumline in [playerStrums, oppStrums])
				strumline.setPosition(strumline.x, FlxG.height - 150);

		uiGroup.add(oppStrums);
		uiGroup.add(playerStrums);
		conductor.onBeatHit.add(beatHit);
		genSong(SONG.sections);
		uiGroup.add(notes);
		add(uiGroup);

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
				var length:Float = sections[i].notes[ii].length;
				var data:Int = sections[i].notes[ii].noteData % 4;

				var oldNote:Note = unspawnNotes[unspawnNotes.length - 1];

				var note:Note = new Note(time, data, false, false, oldNote, 1, conductor);
				note.mustHit = goodHit;
				note.scrollSpeed = SONG.speed;
				note.downscroll = ds;
				note.length = length;
				unspawnNotes.push(note);
				oldNote = unspawnNotes[unspawnNotes.length - 1];
				note.prevNote = oldNote;

				if (length > 0) {
					for (sus in 0...Math.floor(length / conductor.stepLength)) {
						oldNote = unspawnNotes[unspawnNotes.length - 1];
						var sustain:Note = new Note(time + (conductor.stepLength * sus) + (conductor.stepLength / SONG.speed), data, true, note.isPixel,
							oldNote, SONG.speed, conductor);
						sustain.mustHit = note.mustHit;
						sustain.parent = note;
						unspawnNotes.push(sustain);
					}
				}
			}
		}
	
	}

	public var uiGroup:FlxTypedGroup<FlxBasic> = new FlxTypedGroup<FlxBasic>();

	override public function update(elapsed:Float) {
		conductor.songPosition = inst.time;
		keyPress();
		for (value in unspawnNotes) {
			if (value.time - conductor.songPosition < 1600 / SONG.speed) {
				unspawnNotes.remove(value);
				notes.add(value);
			}
		}

		notes.forEach(function(note) {
			var strumGroup = note.mustHit ? playerStrums : oppStrums;
			var strum:StrumNote = strumGroup.members[note.data];

			note.followStrumNote(strum, conductor, SONG.speed);
			if (note.sustainNote)
				note.clipToStrumNote(strum);

			if (!note.mustHit && note.wasGoodHit && !note.wasHit) {
				note.wasGoodHit = true;
				note.wasHit = true;
				strum.playAnim("confirm", true);
				strum.resetTimer = conductor.stepLength * 1.5 / 1000;
				if (!note.sustainNote)
					destroyNote(note);
				return;
			}

			if (conductor.songPosition - note.time > noteKillOffset) {
				if (note.mustHit && !note.ignoreNote && !note.wasGoodHit)
					noteMiss(note.data);

				note.active = note.visible = false;
				destroyNote(note);
			}
		});
		camHUD.zoom = FlxMath.lerp(1,camHUD.zoom,Math.exp(-elapsed * 4));
		super.update(elapsed);
	}

	function destroyNote(note:Note) {
		note.kill();
		notes.remove(note, true);
		note.destroy();
		note = null;
	}

	var hitNotes:Array<Note> = [];
	var directions:Array<Int> = [];
	var dumbNotes:Array<Note> = [];

	function keyPress() {
		hitNotes = []; // notes that can be hit
		directions = []; // directions that the player is able to hit
		dumbNotes = []; // notes to fuck off and kill later
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
		var key:Array<Bool> = [
			FlxG.keys.pressed.LEFT,
			FlxG.keys.pressed.DOWN,
			FlxG.keys.pressed.UP,
			FlxG.keys.pressed.RIGHT
		];
		playerStrums.forEach(function(strumNote) {
			if (keyP[strumNote.data] && strumNote.animation.curAnim.name != "confirm")
				strumNote.playAnim("pressed", true);
			if (keyR[strumNote.data])
				strumNote.playAnim("static");
		});

		notes.forEachAlive(function(note) {
			if (note.mustHit && note.canBeHit(conductor)) {
				hitNotes.push(note);
				hitNotes.sort((a, b) -> Std.int(a.time - b.time));
			}
		});
		if (keyP.contains(true)) {
			notes.forEachAlive(function(daNote:Note) {
				if (daNote.canBeHit(conductor) && daNote.mustHit && !daNote.wasHit) {
					if (directions.contains(daNote.data)) {
						for (coolNote in hitNotes) {
							if (coolNote.data == daNote.data
								&& Math.abs(daNote.time - coolNote.time) < 10) { // if it's the same note twice at < 10ms distance, just delete it
								// EXCEPT u cant delete it in this loop cuz it fucks with the collection lol
								dumbNotes.push(daNote);
								break;
							} else
								if (coolNote.data == daNote.data && daNote.time < coolNote.time) { // if daNote is earlier than existing note (coolNote), replace
								hitNotes.remove(coolNote);
								hitNotes.push(daNote);
								trace("e");
								break;
							}
						}
					} else {
						hitNotes.push(daNote);
						directions.push(daNote.data);
					}
				}
			});

			for (coolNote in dumbNotes)
				destroyNote(coolNote);

			hitNotes.sort((a, b) -> Std.int(a.time - b.time));
			if (hitNotes.length > 0) {
				for (shit in 0...keyP.length) // if a direction is hit that shouldn't be
					if (keyP[shit] && !directions.contains(shit))
						noteMiss(shit);

				for (coolNote in hitNotes)
					if (keyP[coolNote.data])
						goodNoteHit(coolNote);
			}
		}
		notes.forEachAlive(function(susNote:Note) {
			if (susNote.sustainNote && susNote.canBeHit(conductor) && susNote.mustHit && susNote.parent.wasGoodHit && key[susNote.data])
				goodNoteHit(susNote);
		});
	}

	function goodNoteHit(coolNote:Note) {
		if (coolNote.wasGoodHit)
			return;
		coolNote.wasGoodHit = true;
		coolNote.wasHit = true;
		playerStrums.members[coolNote.data].playAnim("confirm", true);
		if (!coolNote.sustainNote)
			destroyNote(coolNote);
	}

	function noteMiss(shit:Int) {
		trace("miss " + shit);
	}

	public function beatHit() {
		notes.sort(FlxSort.byY, FlxSort.DESCENDING);
		if (ds)
			notes.sort(FlxSort.byY, FlxSort.ASCENDING);

		noteKillOffset = Math.max(conductor.stepLength, 350 / SONG.speed);

		if(conductor.curBeat % 4 == 0)
			camHUD.zoom += 0.03;
	}
}
