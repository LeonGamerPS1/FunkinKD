package funkin.objects.gameplay;

import flixel.text.FlxText;
import funkin.controls.Action.Controls;

class PlayField extends FlxTypedGroup<FlxBasic>
{
	public var downScroll:Bool = false;
	public var notes:NoteSpawner;
	public var conductor:Conductor;

	public var oppStrums:StrumLine;
	public var songHits:Int = 0;
	public var playerStrums:StrumLine;

	public var SONG:SongData;
	public var controls:Controls;

	public var noteKillOffset:Float = 350;
	public var time:Float = 0;
	public var healthBar:Bar;
	public var health(default, set):Float = 1;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;

	public var score:FlxText;
	public var misses:FlxText;
	public var rating:FlxText;

	public var Imisses:Int = 0;
	public var Fscore:Float = 0;
	public var sustains:FlxTypedGroup<Sustain> = new FlxTypedGroup<Sustain>();

	public function new(SONG:SongData, controls:Controls)
	{
		super();
		this.SONG = SONG;
		this.controls = controls;

		conductor = new Conductor(SONG.bpm);
		conductor.bpm = SONG.bpm;
		add(conductor);

		playerStrums = new StrumLine(downScroll, true);
		oppStrums = new StrumLine(downScroll, false);

		add(sustains);
		add(oppStrums);
		add(playerStrums);
		

		healthBar = new Bar(0, !downScroll ? FlxG.height - 100 : 100, 'healthBar', () ->
		{
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
		score.setFormat(Paths.font("vcr"), 20, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		score.borderSize = 2;
		add(score);

		misses = new FlxText(healthBar.x + 230, healthBar.y + 45, "Misses: ?");
		misses.setFormat(Paths.font("vcr"), 20, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		misses.screenCenter(X);
		misses.borderSize = 2;
		add(misses);

		rating = new FlxText(misses.x + 230, healthBar.y + 45, "Rating: ?");
		rating.setFormat(Paths.font("vcr"), 20, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		rating.borderSize = 2;
		@:privateAccess
		rating.updateDefaultFormat();
		rating.addFormat(new FlxTextFormat(FlxColor.GRAY,false,false,FlxColor.BLACK),8,9);
		add(rating);

		score.antialiasing = misses.antialiasing = rating.antialiasing = true;

		if (downScroll)
			for (strumline in [playerStrums, oppStrums])
				strumline.setPosition(strumline.x, FlxG.height - 150);

		conductor.onBeatHit.add(beatHit);
		conductor.onStepHit.add(stepHit);
		notes = new NoteSpawner(conductor, SONG, sustains);
		add(notes);
	}

	function destroyNote(note:Note)
	{
		note.kill();
		notes.remove(note, true);
		note.destroy();
		note = null;
	}

	var hitNotes:Array<Note> = [];
	var directions:Array<Int> = [];
	var dumbNotes:Array<Note> = [];

	function keyPress()
	{
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
		playerStrums.forEach(function(strumNote)
		{
			if (keyP[strumNote.data] && strumNote.animation.curAnim.name != "confirm")
				strumNote.playAnim("pressed", true);
			if (keyR[strumNote.data])
				strumNote.playAnim("static");
		});

		notes.forEachAlive(function(note)
		{
			if (note.mustHit && note.canBeHit(conductor))
			{
				hitNotes.push(note);
				hitNotes.sort((a, b) -> Std.int(a.time - b.time));
			}
		});
		if (keyP.contains(true))
		{
			notes.forEachAlive(function(daNote:Note)
			{
				if (daNote.canBeHit(conductor) && daNote.mustHit && !daNote.wasHit)
				{
					if (directions.contains(daNote.data))
					{
						for (coolNote in hitNotes)
						{
							if (coolNote.data == daNote.data && Math.abs(daNote.time - coolNote.time) < 10)
							{ // if it's the same note twice at < 10ms distance, just delete it
								// EXCEPT u cant delete it in this loop cuz it fucks with the collection lol
								dumbNotes.push(daNote);
								break;
							}
							else if (coolNote.data == daNote.data && daNote.time < coolNote.time)
							{ // if daNote is earlier than existing note (coolNote), replace
								hitNotes.remove(coolNote);
								hitNotes.push(daNote);
								trace("e");
								break;
							}
						}
					}
					else
					{
						hitNotes.push(daNote);
						directions.push(daNote.data);
					}
				}
			});

			for (coolNote in dumbNotes)
				destroyNote(coolNote);

			hitNotes.sort((a, b) -> Std.int(a.time - b.time));
			if (hitNotes.length > 0)
			{
				for (shit in 0...keyP.length) // if a direction is hit that shouldn't be
					if (keyP[shit] && !directions.contains(shit))
						noteMiss(shit);

				for (coolNote in hitNotes)
					if (keyP[coolNote.data])
						goodNoteHit(coolNote);
			}
		}
	}

	function goodNoteHit(coolNote:Note)
	{
		var strum = playerStrums.members[coolNote.data];

		var _maxTime:Float = coolNote.time + coolNote.length + conductor.stepLength;
		var _inHoldRange:Bool = coolNote.length > 0 && conductor.songPosition < _maxTime - conductor.stepLength * 2;

		if (plrHitSignal != null)
			plrHitSignal(coolNote.data, !coolNote.wasGoodHit);

		if (!coolNote.wasGoodHit)
		{
			coolNote.wasGoodHit = true;
			coolNote.wasHit = true;

			Fscore += 100.5;
			score.text = 'Score: $Fscore';
			health += 0.04;
			strum.playAnim("confirm", true);
		}

		if (coolNote.wasGoodHit && _maxTime < conductor.songPosition)
			destroyNote(coolNote);
	}

	public var oppHitSignal:(data:Int, ?playAnim:Bool) -> Void;
	public var plrHitSignal:(data:Int, ?playAnim:Bool) -> Void;

	override function update(elapsed:Float)
	{
		conductor.songPosition = time;
		keyPress();

		notes.forEach(function(note:Note)
		{
			var strumGroup = note.mustHit ? playerStrums : oppStrums;
			var strum:StrumNote = strumGroup.members[note.data];
			note.strum = strum;

			note.followStrumNote(strum, conductor, SONG.speed);
			var _maxTime:Float = note.time + note.length + conductor.stepLength;
			var _inHoldRange:Bool = note.length > 0 && conductor.songPosition < _maxTime - conductor.stepLength * 2;

			if (!note.mustHit && note.wasGoodHit)
			{
				if (oppHitSignal != null)
					oppHitSignal(note.data, !note.wasHit);
				if (!note.wasHit)
				{
					note.wasGoodHit = true;
					note.wasHit = true;
				}
			}
			if (note.wasGoodHit
				&& strum.animation.curAnim.name != "confirm"
				&& note.mustHit
				&& note.sustain != null
				&& !(_maxTime - (conductor.stepLength) < conductor.songPosition))
			{
				noteMiss(note.data);
				destroyNote(note);
				return;
			}

			if (note.wasGoodHit && _maxTime < conductor.songPosition)
				destroyNote(note);
			if (conductor.songPosition - note.time - note.length > noteKillOffset && note.mustHit)
			{
				if (note.mustHit && !note.ignoreNote && !note.wasGoodHit)
					noteMiss(note.data);

				note.active = note.visible = false;

				destroyNote(note);
			}
			note.cameras = cameras;
		});
		super.update(elapsed);

		iconP1.x = (healthBar.barCenter + (150 * iconP1.scale.x) / 2 - 150) + 50;
		iconP2.x = (healthBar.barCenter - (150 * iconP1.scale.x) / 2) - 50;
	}

	function noteMiss(shit:Int)
	{
		health -= 0.04;
		FlxG.sound.play(Paths.soundRandom("missnote", 1, 3), 0.5);
		Imisses++;
		misses.text = 'Misses: $Imisses';
		missCallback(shit);
	}

	public dynamic function missCallback(shit:Int)
	{
	}

	public function beatHit()
	{
		noteKillOffset = Math.max(conductor.stepLength, 350 / SONG.speed);
		notes.sort(FlxSort.byY, FlxSort.DESCENDING);
		if (downScroll)
			notes.sort(FlxSort.byY, FlxSort.ASCENDING);
		if (SONG.sections[Math.floor(conductor.curStep / 16)] != null)
		{
			if (SONG.sections[Math.floor(conductor.curStep / 16)].changeBPM)
			{
				conductor.bpm = (SONG.sections[Math.floor(conductor.curStep / 16)].bpm);
			};
		}
	}

	public function stepHit()
	{
		iconP1.stepHit(conductor.curStep);
		iconP2.stepHit(conductor.curStep);
	}

	function set_health(value:Float):Float
	{
		value = FlxMath.bound(value, 0, 2);
		health = value;
		return value;
	}
}
