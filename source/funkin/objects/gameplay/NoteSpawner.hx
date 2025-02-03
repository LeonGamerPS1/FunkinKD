package funkin.objects.gameplay;

import funkin.backend.Song.SongData;
import funkin.backend.Conductor;
import funkin.backend.Song.Section;
import flixel.group.FlxGroup.FlxTypedGroup;


class NoteSpawner extends FlxTypedGroup<Note>
{
	public var unspawnNotes:Array<Note> = [];
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

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (unspawnNotes[0] != null)
		{
			if (unspawnNotes[0].time - conductor.songPosition < 2300 / song.speed)
			{
				add(unspawnNotes[0]);

				unspawnNotes.remove(unspawnNotes[0]);
			}
		}
	}

	public function genSong(sections:Array<Section>)
	{
		for (i in 0...sections.length)
		{
			for (ii in 0...sections[i].notes.length)
			{
				if(sections[i].notes[ii].noteData < 0)
					continue;
				var time:Float = sections[i].notes[ii].time;
				var goodHit:Bool = sections[i].notes[ii].noteData > 3;
				var length:Float = sections[i].notes[ii].length;
				var data:Int = sections[i].notes[ii].noteData % 4;

				var oldNote:Note = unspawnNotes[unspawnNotes.length - 1];

				var note:Note = new Note(time, data, PlayState.isPixelStage, oldNote, 1, conductor);
				note.mustHit = goodHit;
				note.scrollSpeed = song.speed;
				note.length = length;

				unspawnNotes.push(note);
				oldNote = unspawnNotes[unspawnNotes.length - 1];
				note.prevNote = oldNote;

				if (Math.floor(length / conductor.stepLength) > 0)
				{
					note.sustain = new Sustain(note);
					note.sustain.init();
					sustainGroup.add(note.sustain);
				}
			}
		}
		unspawnNotes.sort(yessort);
	}

	function yessort(Obj1, Obj2):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.time, Obj2.time);
	}
}
