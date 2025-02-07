package funkin.objects.gameplay;

import funkin.backend.Song.SongData;
import funkin.backend.Conductor;
import funkin.backend.Song.Section;
import flixel.group.FlxGroup.FlxTypedGroup;

class NoteSpawner extends FlxTypedGroup<Note>
{
	public var unspawnNotes:Array<funkin.backend.recycling.data.ChartNote> = [];
	public var conductor:Conductor;
	public var song:SongData;
	public var sustainGroup:FlxTypedGroup<Sustain>;

	public function new(conductor:Conductor, song:SongData, sustainGroup:FlxTypedGroup<Sustain>)
	{
		super();
		this.conductor = conductor;
		this.song = song;
		this.sustainGroup = sustainGroup;
		if (sustainGroup == null)
			throw new haxe.exceptions.ArgumentException("sustainGroup", "Sustain group cannot be null.");
	}

	var spawnNotesAtOnce:Int = 22;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		for (i in 0...spawnNotesAtOnce)
		{
			if (unspawnNotes[i] != null)
			{
				if (unspawnNotes[i].time - conductor.songPosition < 3000 / song.speed)
				{
					var preloadedNote = unspawnNotes[i];
					var note = recycle(Note).setup(preloadedNote);

					add(note);
					note.conductor = conductor;

					if (Math.floor(preloadedNote.length / conductor.stepLength) > 0)
					{
						var sustain:Sustain = sustainGroup.recycle(Sustain).setup(note);
						note.sustain = sustain;
						sustainGroup.add(sustain);
					}

					unspawnNotes.remove(unspawnNotes[i]);
				}
			}
		}
	}

	public function genSong(sections:Array<Section>)
	{
		for (i in 0...sections.length)
		{
			for (ii in 0...sections[i].notes.length)
			{
				if (sections[i].notes[ii][3] < 0)
					continue;
				var time:Float = sections[i].notes[ii][0];
				var data:Int = Std.int(sections[i].notes[ii][1] % 4);
				var length:Float = sections[i].notes[ii][2];

				var goodHit:Bool = sections[i].notes[ii][1] > 3;

				var preloadedNote:funkin.backend.recycling.data.ChartNote = {
					time: time,
					mustHit: goodHit,
					length: length,
					data: data,
					pixel: PlayState.isPixelStage,
					speed: song.speed
				};
				unspawnNotes.push(preloadedNote);
			}
		}
		unspawnNotes.sort(yessort);
		
	}

	function yessort(Obj1, Obj2):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.time, Obj2.time);
	}
}
