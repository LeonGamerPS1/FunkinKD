package funkin.objects.gameplay;

import funkin.backend.Song.SongData;
import funkin.backend.Conductor;
import funkin.backend.Song.Section;
import flixel.group.FlxGroup.FlxTypedGroup;

class NoteSpawner extends FlxTypedGroup<Note> {
	public var unspawnNotes:Array<Note> = [];
	public var conductor:Conductor;
	public var song:SongData;

	public function new(conductor:Conductor, song:SongData) {
		super();
		this.conductor = conductor;
		this.song = song;
	}

	var spawnNotesAtOnce:Int = 22;

	override function update(elapsed:Float) {
		super.update(elapsed);

		for (i in 0...spawnNotesAtOnce) {
			if (unspawnNotes[i] != null) {
				if (unspawnNotes[i].time - conductor.songPosition < 3000 / song.speed) {
					var preloadedNote = unspawnNotes[i];

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
				if (sections[i].notes[ii][3] < 0)
					continue;
				var time:Float = sections[i].notes[ii][0];
				var data:Int = Std.int(sections[i].notes[ii][1] % 4);
				var length:Float = sections[i].notes[ii][2];
				var goodHit:Bool = sections[i].notes[ii][1] > 3;

				var oldNote:Note = null;
				if (unspawnNotes[unspawnNotes.length - 1] != null)
					oldNote = unspawnNotes[unspawnNotes.length - 1];

				var note:Note = new Note(time, data, PlayState.isPixelStage, oldNote, song.speed, conductor);
				note.mustHit = goodHit;
				unspawnNotes.push(note);

				if (length > 0) {
					for (susNote in 0...Math.floor(length / conductor.stepLength)) {
						oldNote = unspawnNotes[unspawnNotes.length - 1];
						var sustainTime = time + (conductor.stepLength * susNote) + (conductor.stepLength / song.speed);
						var sustain:Note = new Note(sustainTime, data, note.isPixel, oldNote, song.speed, conductor, true);
						sustain.parent = note;
						sustain.mustHit = goodHit;
						unspawnNotes.push(sustain);

						if (PlayState.instance != null)
							sustain.cameras = [PlayState.instance.camUnderlay];
					}
				}
			}
		}
		unspawnNotes.sort(yessort);
	}

	function yessort(Obj1, Obj2):Int {
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.time, Obj2.time);
	}
}
