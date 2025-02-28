package funkin.substates;

import flixel.addons.transition.FlxTransitionableState;
import funkin.objects.gameplay.PlayField;

class EditorPlayState extends BaseState {
	public var dong:Dynamic;
	public var playField:PlayField;
	public var inst:FlxSound;
	public var voices:FlxSound;

	public function new(song) {
		super();
		this.dong = song;
	}

	override function create() {
		PlayState.instance = null;
		FlxTransitionableState.skipNextTransOut = true;
		super.create();
		playField = new PlayField(dong, controls);
		playField.healthBar.kill();
		playField.iconP1.kill();
		playField.iconP2.kill();
		playField.notes.genSong(dong.sections);
		add(playField);

		inst = new FlxSound();
		inst.loadEmbedded(Paths.inst(dong.song), false, false, function() {
			FlxG.switchState(new ChartingState());
		});
		inst.play();

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
