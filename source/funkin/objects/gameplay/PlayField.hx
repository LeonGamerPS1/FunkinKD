package funkin.objects.gameplay;

import funkin.controls.Action.Controls;

class PlayField extends FlxTypedGroup<FlxBasic>
{
	public var downScroll:Bool = false;
	public var notes:NoteSpawner;
	public var conductor:Conductor;

	public var oppStrums:StrumLine;
	public var playerStrums:StrumLine;

	public var SONG:SongData;
	public var controls:Controls;

	public var noteKillOffset:Float = 350;
	public var time:Float = 0;

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

		add(oppStrums);
		add(playerStrums);

		if (downScroll)
			for (strumline in [playerStrums, oppStrums])
				strumline.setPosition(strumline.x, FlxG.height - 150);

		conductor.onBeatHit.add(beatHit);
		notes = new NoteSpawner(conductor, SONG);
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
		notes.forEachAlive(function(susNote:Note)
		{
			if (susNote.sustainNote && susNote.canBeHit(conductor) && susNote.mustHit && susNote.parent.wasGoodHit && key[susNote.data])
				goodNoteHit(susNote);
		});
	}

	function goodNoteHit(coolNote:Note)
	{
		if (coolNote.wasGoodHit)
			return;
		coolNote.wasGoodHit = true;
		coolNote.wasHit = true;
		playerStrums.members[coolNote.data].playAnim("confirm", true);
		if (!coolNote.sustainNote)
			destroyNote(coolNote);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		notes.sort(FlxSort.byY, FlxSort.DESCENDING);
		if (downScroll)
			notes.sort(FlxSort.byY, FlxSort.ASCENDING);

		conductor.songPosition = time;
		keyPress();

		notes.forEach(function(note)
		{
			var strumGroup = note.mustHit ? playerStrums : oppStrums;
			var strum:StrumNote = strumGroup.members[note.data];

			note.followStrumNote(strum, conductor, SONG.speed);
			if (note.sustainNote)
				note.clipToStrumNote(strum);

			if (!note.mustHit && note.wasGoodHit && !note.wasHit)
			{
				note.wasGoodHit = true;
				note.wasHit = true;
				strum.playAnim("confirm", true);
				strum.resetTimer = conductor.stepLength * 1.5 / 1000;
				if (!note.sustainNote)
					destroyNote(note);
				return;
			}

			if (conductor.songPosition - note.time > noteKillOffset)
			{
				if (note.mustHit && !note.ignoreNote && !note.wasGoodHit)
					noteMiss(note.data);

				note.active = note.visible = false;
				destroyNote(note);
			}
		});
	}

	function noteMiss(shit:Int)
	{
		trace("miss " + shit);
	}

	public function beatHit()
	{
		noteKillOffset = Math.max(conductor.stepLength, 350 / SONG.speed);
	}
}
