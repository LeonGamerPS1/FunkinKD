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

	override function update(elapsed:Float) {
		super.update(elapsed);
		if (unspawnNotes[0] != null) {
			if (unspawnNotes[0].time - conductor.songPosition < 2300 / song.speed) {
				add(unspawnNotes[0]);

				unspawnNotes.remove(unspawnNotes[0]);
			}
		}

	
	}

	public function genSong(sections:Array<Section>) {
		for (i in 0...sections.length) {
			for (ii in 0...sections[i].notes.length) {
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

				if (Math.floor(length / conductor.stepLength) > 0) {
					note.sustain = new Sustain(note);
					note.sustain.init();
				}
			}
		}
		unspawnNotes.sort(yessort);
	}

	function yessort(Obj1, Obj2):Int {
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.time, Obj2.time);
	}
}
