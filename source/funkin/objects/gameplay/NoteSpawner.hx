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

	public function new(conductor:Conductor,song:SongData)
	{
		super();
        this.conductor = conductor;
        this.song = song;
	}

	override function update(elapsed:Float)
	{
		if(unspawnNotes[0] != null)
			if (value.time - conductor.songPosition < 1600 / song.speed)
			{
				unspawnNotes.remove(value);
				add(value);
			}
		}

		super.update(elapsed);
	}

	public function genSong(sections:Array<Section>)
	{
		for (i in 0...sections.length)
		{
			for (ii in 0...sections[i].notes.length)
			{
				var time:Float = sections[i].notes[ii].time;
				var goodHit:Bool = sections[i].notes[ii].noteData > 3;
				var length:Float = sections[i].notes[ii].length;
				var data:Int = sections[i].notes[ii].noteData % 4;

				var oldNote:Note = unspawnNotes[unspawnNotes.length - 1];

				var note:Note = new Note(time, data, false, PlayState.isPixelStage, oldNote, 1, conductor);
				note.mustHit = goodHit;
				note.scrollSpeed = song.speed;
				note.length = length;
				unspawnNotes.push(note);
				oldNote = unspawnNotes[unspawnNotes.length - 1];
				note.prevNote = oldNote;

				if (length > 0)
				{
					for (sus in 0...Math.floor(length / conductor.stepLength))
					{
						oldNote = unspawnNotes[unspawnNotes.length - 1];
						var sustain:Note = new Note(time + (conductor.stepLength * sus) + (conductor.stepLength / song.speed), data, true, note.isPixel,
							oldNote, song.speed, conductor);
						sustain.mustHit = note.mustHit;
						sustain.parent = note;
						unspawnNotes.push(sustain);
					}
				}
			}
		}
	}
}
