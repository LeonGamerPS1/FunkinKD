package funkin.objects.gameplay;

import flixel.text.FlxText;
import funkin.controls.Action.Controls;

class PlayField extends FlxTypedGroup<FlxBasic> {
	public var downScroll:Bool = false;
	public var notes:NoteSpawner;
	public var conductor:Conductor;

	public var oppStrums:StrumLine;
	public var songHits:Int = 0;
	public var playerStrums:StrumLine;

	public var SONG:SongData;
	public var controls:Controls;
	public var botplay:Bool = #if bplay true #else false #end;

	public var noteKillOffset:Float = 350;
	public var time:Float = 0;
	public var healthBar:Bar;
	public var health(default, set):Float = 1;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;

	public var score:FlxText;

	public var Imisses:Int = 0;
	public var Fscore:Float = 0;

	public function new(SONG:SongData, controls:Controls) {
		super();
		this.SONG = SONG;
		this.controls = controls;

		conductor = new Conductor(SONG.bpm);
		conductor.bpm = SONG.bpm;
		add(conductor);

		playerStrums = new StrumLine(downScroll, true);
		oppStrums = new StrumLine(downScroll, false);

		for (strumline in [oppStrums, playerStrums])
			for (member in strumline.members)
				strumLineNotes.add(member);

		healthBar = new Bar(0, !downScroll ? FlxG.height - 100 : 100, 'healthBar', () -> {
			return health;
		}, 0, 2);
		healthBar.setColors(FlxColor.RED, FlxColor.LIME);
		healthBar.leftToRight = false;
		healthBar.screenCenter(X);
		add(healthBar);

		iconP1 = new HealthIcon("bf", true);
		iconP2 = new HealthIcon("dad");
		add(iconP1);
		add(iconP2);

		iconP1.y = iconP2.y = healthBar.y - 80;

		score = new FlxText(healthBar.leftBar.x, healthBar.y + 45, 0, "Score: ?");
		score.setFormat(Paths.font("vcr"), 15, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		score.borderSize = 2;
		add(score);

		score.antialiasing = true;

		if (downScroll)
			for (strumline in [playerStrums, oppStrums])
				strumline.setPosition(strumline.x, FlxG.height - 150);

		conductor.onBeatHit.add(beatHit);
		conductor.onStepHit.add(stepHit);
		notes = new NoteSpawner(conductor, SONG);

		add(playerStrums);
		add(oppStrums);
		add(notes);
	}

	function destroyNote(note:Note) {
		note.kill();
		notes.remove(note, true);
		note.destroy();
	}

	var hitNotes:Array<Note> = [];
	var directions:Array<Int> = [];
	var dumbNotes:Array<Note> = [];

	function keyPress() {
		hitNotes = []; // notes that can be hit
		directions = []; // directions that the player is able to hit
		dumbNotes = []; // notes to fuck off and kill later
		var keyP:Array<Bool> = [
			controls.justPressed.NOTE_LEFT,
			controls.justPressed.NOTE_DOWN,
			controls.justPressed.NOTE_UP,
			controls.justPressed.NOTE_RIGHT,

		];
		var keyR:Array<Bool> = [
			controls.justReleased.NOTE_LEFT,
			controls.justReleased.NOTE_DOWN,
			controls.justReleased.NOTE_UP,
			controls.justReleased.NOTE_RIGHT,
		];
		var key:Array<Bool> = [
			controls.pressed.NOTE_LEFT,
			controls.pressed.NOTE_DOWN,
			controls.pressed.NOTE_UP,
			controls.pressed.NOTE_RIGHT,
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
					hitNotes.push(daNote);
					directions.push(daNote.data);
				}
			});

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
		notes.forEachAlive(function(e) {
			if (key[e.data] && e.isSustainNote && e.parent.wasGoodHit && e.canBeHit(conductor))
				goodNoteHit(e);
		});
	}

	function goodNoteHit(coolNote:Note) {
		if (coolNote.wasGoodHit || coolNote.wasHit)
			return;
		var strum = playerStrums.members[coolNote.data];

		if (plrHitSignal != null)
			plrHitSignal(coolNote.data, true);

		if (!coolNote.wasGoodHit) {
			coolNote.wasGoodHit = true;
			coolNote.wasHit = true;
			if (!coolNote.isSustainNote)
				destroyNote(coolNote);

			Fscore += 100.5;

			health += 0.04;
			strum.playAnim("confirm", true);
		}
	}

	public var oppHitSignal:(data:Int, ?playAnim:Bool) -> Void;
	public var plrHitSignal:(data:Int, ?playAnim:Bool) -> Void;
	public var tick = false;
	public var strumLineNotes:FlxTypedGroup<StrumNote> = new FlxTypedGroup<StrumNote>();

	override function update(elapsed:Float) {
		conductor.songPosition = time;
		if (!botplay)
			keyPress();

		super.update(elapsed);
		score.text = 'Score : $Fscore | Misses : $Imisses | Rating : ?';
		score.screenCenter(X);
		notes.forEachAlive(function(note:Note) {
			var strumGroup = note.mustHit ? playerStrums : oppStrums;
			var strum:StrumNote = strumGroup.members[note.data];
			note.strum = strum;

			note.followStrumNote(strum, conductor, SONG.speed);

			if (note.mustHit && botplay && !note.wasGoodHit) {
				if (note.time <= conductor.songPosition
					|| note.isSustainNote
					&& (note.prevNote.wasGoodHit || note.parent.wasGoodHit)
					&& note.canBeHit(conductor)) {
					goodNoteHit(note);
					note.wasGoodHit = true;
					strum.resetTimer = conductor.stepLength * 1.5 / 1000;
				}
			}

			if (note.isSustainNote)
				note.clipToStrumNote(strum);

			if (!note.mustHit && note.wasGoodHit && !note.wasHit) {
				if (oppHitSignal != null)
					oppHitSignal(note.data, !note.wasHit);

				note.wasGoodHit = true;
				note.wasHit = true;

				if (!note.isSustainNote)
					destroyNote(note);
			}

			if (conductor.songPosition - note.time > noteKillOffset) {
				if (note.mustHit && !note.ignoreNote && !note.wasGoodHit && !botplay && !note.wasMissed) {
					noteMiss(note.data);
					note.wasMissed = true;
				}

				note.active = note.visible = false;

				destroyNote(note);
			}
			note.cameras = cameras;
		});

		iconP1.x = FlxMath.lerp((healthBar.barCenter + (150 * iconP1.scale.x) / 2 - 150) + 50, iconP1.x, 0.1);
		iconP2.x = FlxMath.lerp((healthBar.barCenter - (150 * iconP2.scale.x) / 2) - 50, iconP2.x, 0.1);
		iconP1.origin.y = 0;
		iconP2.origin.y = 0;
		tick = false;
	}

	function noteMiss(shit:Int) {
		health -= 0.04;
		FlxG.sound.play(Paths.soundRandom("missnote", 1, 3), 0.5);
		Imisses++;

		missCallback(shit);
	}

	public dynamic function missCallback(shit:Int) {}

	public function beatHit() {
		noteKillOffset = Math.max(conductor.stepLength, 350 / SONG.speed);

		notes.sort(FlxSort.byY, FlxSort.DESCENDING);
		if (downScroll)
			notes.sort(FlxSort.byY, FlxSort.ASCENDING);

		if (SONG.sections[Math.floor(conductor.curStep / 16)] != null) {
			if (SONG.sections[Math.floor(conductor.curStep / 16)].changeBPM) {
				conductor.bpm = (SONG.sections[Math.floor(conductor.curStep / 16)].bpm);
			};
		}
	}

	public function stepHit() {
		iconP1.stepHit(conductor.curStep);
		iconP2.stepHit(conductor.curStep);
		tick = true;
	}

	function set_health(value:Float):Float {
		value = FlxMath.bound(value, 0, 2);
		health = value;
		return value;
	}
}
