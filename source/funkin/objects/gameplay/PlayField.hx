package funkin.objects.gameplay;

import openfl.system.System;
import flixel.util.FlxStringUtil;
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
	public var sustains:FlxTypedGroup<Sustain> = new FlxTypedGroup();

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
		this.downScroll = ClientPrefs.save.downScroll;
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

		notes = new NoteSpawner(conductor, SONG);
		notes.sustainGroup = sustains;

		add(sustains);
		add(playerStrums);
		add(oppStrums);
		add(notes);

		noteSplashes = new FlxTypedGroup<NoteSplash>(ClientPrefs.save.maxSplashes);
		add(noteSplashes);

		setupSplash();

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

		iconP1.y = iconP2.y = healthBar.y - 75;

		score = new FlxText(healthBar.leftBar.x, healthBar.y + 45, 0, "Score: ?");
		score.setFormat(Paths.font("vcr"), 18, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		score.borderSize = 1;
		add(score);

		var infoText = new FlxText(0, FlxG.height - 25, 0, '${SONG.song} - ${PlayState.weekDifficulty} | FunkinKD v0.0.1');
		infoText.setFormat(Paths.font("vcr"), 15, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		infoText.borderSize = 1;
		add(infoText);

		score.antialiasing = true;

		if (downScroll)
			for (strumline in [playerStrums, oppStrums])
				strumline.setPosition(strumline.x, FlxG.height - 150);

		conductor.onBeatHit.add(beatHit);
		conductor.onStepHit.add(stepHit);
	}

	/**
	 * Spawns a NoteSplash.
	 * @param id  The NoteData of the Splash.
	 * @param strum The StrumNote the splash should Position itself to (if null, it will go to 0,0).
	 */
	public function setupSplash(id:Int = 0, ?strum:StrumNote) {
		var splash:NoteSplash = noteSplashes.recycle(NoteSplash).setup(id, strum);
		noteSplashes.add(splash);
	}

	function destroyNote(note:Note) {
		if (note.sustain != null) {
			note.sustain.kill();
			sustains.remove(note.sustain, true);
			note.sustain.destroy();
			note.sustain = null;
		}
		note.kill();
		notes.remove(note, true);
		note.destroy();
		note = null;
		System.gc();
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
	}

	function goodNoteHit(coolNote:Note) {
		var strum = playerStrums.members[coolNote.data];

		var _maxTime:Float = coolNote.time + coolNote.length;
		var _inHoldRange:Bool = coolNote.length > 0 && conductor.songPosition < _maxTime - conductor.stepLength * 2;

		if (plrHitSignal != null)
			plrHitSignal(coolNote, !coolNote.wasHit);

		if (!coolNote.wasGoodHit) {
			coolNote.wasGoodHit = true;
			coolNote.wasHit = true;

			popUpScore(coolNote);

			health += 0.04;
			strum.playAnim("confirm", true);
		}

		if (tick) {
			strum.playAnim("confirm", true);
			plrHitSignal(coolNote, true);
		}
		if (coolNote.wasGoodHit && _maxTime < conductor.songPosition)
			destroyNote(coolNote);
	}

	function popUpScore(coolNote:Note) {
		var diff:Float = Math.abs(coolNote.time - conductor.songPosition);

		var rating = "?";
		if (diff < ClientPrefs.save.sickWindow)
			rating = "sick";
		else if (diff < ClientPrefs.save.goodWindow)
			rating = "good";
		else if (diff < ClientPrefs.save.badWindow)
			rating = "bad";
		else
			rating = "shit";

		coolNote.rating = rating;
		if (PlayState.instance != null)
			@:privateAccess
			PlayState.instance.call('goodNoteHit', [coolNote.time, coolNote.data, coolNote.length, notes.members.indexOf(coolNote)]);
		if (popupSprite == null)
			popupSprite = new FlxSprite(0, 0, Paths.image('ratings/$rating' + (PlayState.isPixelStage ? '-pixel' : "")));

		add(popupSprite);
		popupSprite.loadGraphic(Paths.image('ratings/$rating' + (PlayState.isPixelStage ? '-pixel' : "")));
		popupSprite.alpha = 1;
		popupSprite.antialiasing = !PlayState.isPixelStage;
		if (PlayState.isPixelStage) {
			popupSprite.setGraphicSize(popupSprite.width * PlayState.daPixelZoom);
			popupSprite.updateHitbox();
		}
		popupSprite.screenCenter();
		popupSprite.x -= popupSprite.width / 2;
		FlxTween.cancelTweensOf(popupSprite);

		popupSprite.acceleration.set();
		popupSprite.velocity.set();

		popupSprite.acceleration.y = 550;
		popupSprite.velocity.y -= FlxG.random.int(140, 175);
		popupSprite.velocity.x -= FlxG.random.int(0, 10);
		FlxTween.tween(popupSprite, {alpha: 0}, conductor.stepLength * 5.4 / 1000);

		if(!botplay)
		Fscore += Rating.scoreAddfromRating(rating);

		if (rating == "sick")
			setupSplash(coolNote.data, coolNote.strum);
	}

	public var popupSprite:FlxSprite;

	public var oppHitSignal:(note:Note, ?p:Bool) -> Void;
	public var plrHitSignal:(note:Note, ?p:Bool) -> Void;
	public var tick(get, null):Bool;
	public var strumLineNotes:FlxTypedGroup<StrumNote> = new FlxTypedGroup<StrumNote>();

	public function get_tick():Bool {
		return (conductor != null && conductor.curStep % 2 == 0);
	}

	override function update(elapsed:Float) {
		conductor.songPosition = time;
		if (!botplay)
			keyPress();

		if (!botplay)
			score.text = 'Score: $Fscore | Misses : $Imisses';
		else
			score.text = 'BOTPLAY';
		score.screenCenter(X);
		super.update(elapsed);
		notes.forEachAlive(function(note:Note) {
			var strumGroup = note.mustHit ? playerStrums : oppStrums;
			var strum:StrumNote = strumGroup.members[note.data];
			note.strum = strum;

			note.followStrumNote(strum, conductor, SONG.speed);

			var _maxTime:Float = note.time + note.length;
			// var _inHoldRange:Bool = note.length > 0 && conductor.songPosition < _maxTime - conductor.stepLength * 2;

			if (!note.mustHit && note.wasGoodHit) {
				if (oppHitSignal != null)
					oppHitSignal(note, !note.wasHit);
				if (!note.wasHit) {
					note.wasGoodHit = true;
					note.wasHit = true;
					strum.playAnim("confirm", true);
				}
				if (tick && note.sustain != null && strum.resetTimer > 0) {
					oppHitSignal(note, true);
					strum.playAnim("confirm", true);
				}
				strum.resetTimer = conductor.stepLength * 1.5 / 1000;
			}
			if (botplay && note.time <= conductor.songPosition && note.mustHit) {
				goodNoteHit(note);
				strum.resetTimer = conductor.stepLength * 1.5 / 1000;
			}
			if (tick && note.sustain != null && note.mustHit && note.wasGoodHit && strum.animation.curAnim.name == "confirm" && !botplay) {
				plrHitSignal(note, tick);
				strum.playAnim("confirm", tick);
			}
			if (note.wasGoodHit
				&& strum.animation.curAnim.name != "confirm"
				&& note.mustHit
				&& note.sustain != null
				&& !(_maxTime - (conductor.stepLength) < conductor.songPosition)) {
				destroyNote(note);
				return;
			}

			if (note.tooLate && note.mustHit && !note.glowing) {
				note.glowing = true;
				trace("weed");
				FlxTween.color(note, 0.2, note.color, FlxColor.GRAY);
				if (note.sustain != null)
					FlxTween.color(note.sustain, 0.2, note.sustain.color, FlxColor.GRAY);
			}

			if (note.wasGoodHit && _maxTime < conductor.songPosition)
				destroyNote(note);
			if (conductor.songPosition - note.time - note.length > noteKillOffset) {
				if (note.mustHit && !note.ignoreNote && !note.wasGoodHit && note.mustHit)
					noteMiss(note.data);

				note.active = note.visible = false;

				destroyNote(note);
			}
			note.cameras = cameras;
		});

		iconP1.x = FlxMath.lerp((healthBar.barCenter + (150 * iconP1.scale.x) / 2 - 150) + 50, iconP1.x, 0.1);
		iconP2.x = FlxMath.lerp((healthBar.barCenter - (150 * iconP2.scale.x) / 2) - 50, iconP2.x, 0.1);

		if (healthBar.percent < 20) {
			iconP1.animation.curAnim.curFrame = 1;
			iconP2.animation.curAnim.curFrame = 0;
		} else if (healthBar.percent > 80) {
			iconP2.animation.curAnim.curFrame = 1;
			iconP1.animation.curAnim.curFrame = 0;
		} else {
			iconP2.animation.curAnim.curFrame = 0;
			iconP1.animation.curAnim.curFrame = 0;
		}
	}

	public var noteSplashes:FlxTypedGroup<NoteSplash>;

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
	}

	function set_health(value:Float):Float {
		value = FlxMath.bound(value, 0, 2);
		health = value;
		return value;
	}
}
