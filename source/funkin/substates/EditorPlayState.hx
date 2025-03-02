package funkin.substates;

import flixel.addons.transition.FlxTransitionableState;
import funkin.objects.gameplay.PlayField;

class EditorPlayState extends BaseSubState {
	public var dong:Dynamic;
	public var playField:PlayField;
	public var inst:FlxSound;
	public var voices:FlxSound;
	public var cameraHUD:FlxCamera;
	public var time:Float = 0;

	public function new(song, time:Float = 0) {
		super();
		this.dong = song;
		cameraHUD = new FlxCamera();

		cameraHUD.bgColor.alpha = 0;
		this.time = time;
	}

	override function destroy() {
		super.destroy();

		FlxG.cameras.remove(cameraHUD);
		cameraHUD = null;
	}

	override function create() {
		FlxG.cameras.add(cameraHUD, false);
		cameras = [cameraHUD];

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0x75000000);
		bg.cameras = [cameraHUD];
		add(bg);

		PlayState.instance = null;
		FlxTransitionableState.skipNextTransOut = true;
		super.create();
		playField = new PlayField(dong, controls);
		playField.healthBar.kill();
		playField.iconP1.kill();
		playField.iconP2.kill();
		playField.notes.genSong(dong.sections, time);
		playField.scrollFactor(0);
		playField.cameras = [cameraHUD];
		for (KvIT in playField.notes.unspawnNotes.keyValueIterator()) {
			if (KvIT.value.time < time) {
				playField.notes.unspawnNotes.remove(KvIT.value);
				KvIT.value.destroy();
				if (KvIT.value.sustain != null)
					KvIT.value.sustain.destroy();
				KvIT.value.sustain = null;
				KvIT.value = null;
			}
		}
		add(playField);

		inst = new FlxSound();
		inst.loadEmbedded(Paths.inst(dong.song), false, false, function() {
			close();
			inst.kill;
			inst.destroy();
		});
		inst.play();
		inst.time = time;

		if (Assets.exists(Paths.voices(dong.song))) {
			voices = new FlxSound();
			voices.loadEmbedded(Paths.voices(dong.song));

			FlxG.sound.list.add(voices);
		}

		if (voices != null)
			voices.play();

		FlxG.sound.list.add(inst);
	}

	override function update(elapsed:Float) {
		playField.time = inst.time;

		super.update(elapsed);

		if (controls.justPressed.UI_BACK)
			inst.time = inst.length - 10;

		if (inst.playing && voices != null)
			if (Math.abs(voices.time - inst.time) > 20)
				voices.time = inst.time;
	}
}
