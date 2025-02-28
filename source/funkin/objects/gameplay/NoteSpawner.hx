package funkin.objects.gameplay;

import funkin.backend.Song.SongData;
import funkin.backend.Conductor;
import funkin.backend.Song.Section;
import flixel.group.FlxGroup.FlxTypedGroup;

class NoteSpawner extends FlxTypedGroup<Note> {
	public var unspawnNotes:Array<Note> = [];
	public var conductor:Conductor;
	public var song:SongData;
	public var sustainGroup:FlxTypedGroup<Sustain>;

	public function new(conductor:Conductor, song:SongData) {
		super();
		this.conductor = conductor;
		this.song = song;
	}

	var spawnNotesAtOnce:Int = 2;

	override function update(elapsed:Float) {
		super.update(elapsed);

		for (i in 0...spawnNotesAtOnce) {
			if (unspawnNotes[i] != null) {
				if (unspawnNotes[i].time - conductor.songPosition < 3000 / song.speed) {
					var preloadedNote = unspawnNotes[i];

					if (preloadedNote.sustain != null)
						preloadedNote.sustain.visible = true;
					add(preloadedNote);
					preloadedNote.conductor = conductor;

					unspawnNotes.remove(unspawnNotes[i]);
				}
			}
		}
	}

	public function genSong(sections:Array<Section>) {
		for (i in 0...sections.length) {
			for (ii in 0...sections[i].notes.length) {
				if (sections[i].notes[ii][1] < 0)
					continue;
				var time:Float = sections[i].notes[ii][0];
				var data:Int = Std.int(sections[i].notes[ii][1] % 4);
				var length:Float = sections[i].notes[ii][2] is String ? 0 : sections[i].notes[ii][2];
				var noteType:String = sections[i].notes[ii][3] != null ? sections[i].notes[ii][3] : "normal";
				var goodHit:Bool = sections[i].notes[ii][1] > 3;

				var oldNote:Note = null;
				if (unspawnNotes[unspawnNotes.length - 1] != null)
					oldNote = unspawnNotes[unspawnNotes.length - 1];

				var note:Note = new Note(time, data, PlayState.isPixelStage, oldNote, song.speed, conductor, noteType);
				note.mustHit = goodHit;
				note.altNote = (sections[i].altSection == true);
				note.length = length;
				note.scrollSpeed = song.speed;
				unspawnNotes.push(note);

				if (length > 0) {
					note.sustain = new Sustain(note);
					sustainGroup.add(note.sustain);
					note.sustain.visible = false;
				}
			}
		}
		unspawnNotes.sort(yessort);
	}

	function yessort(Obj1, Obj2):Int {
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.time, Obj2.time);
	}
}
