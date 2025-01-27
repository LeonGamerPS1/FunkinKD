package funkin.states;

import funkin.objects.gameplay.PlayField;

class PlayState extends BaseState
{
	public static var SONG:SongData;

	public var inst:FlxSound;
	public var ds:Bool = true;

	public var camUnderlay:FlxCamera;
	public var camHUD:FlxCamera;

	public var playField:PlayField;

	override public function create()
	{
		if (SONG == null)
			SONG = Song.parseSong();

		camHUD = new FlxCamera();
		camUnderlay = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camUnderlay.bgColor.alpha = 0;

		FlxG.cameras.add(camUnderlay, false);
		FlxG.cameras.add(camHUD, false);

		playField = new PlayField(SONG, controls);
		playField.cameras = [camHUD];
		uiGroup.add(playField);

		playField.conductor.onBeatHit.add(beatHit);

		super.create();

		genSong(SONG.sections);

		add(uiGroup);

		inst = new FlxSound();
		inst.loadEmbedded(Paths.inst(SONG.song));
		FlxG.sound.list.add(inst);
		inst.time = -playField.conductor.beatLength * 4;
		inst.play();
	}

	function genSong(sections:Array<Section>)
	{
		playField.notes.genSong(sections);
	}

	public var uiGroup:FlxTypedGroup<FlxBasic> = new FlxTypedGroup<FlxBasic>();

	override public function update(elapsed:Float)
	{
		camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, Math.exp(-elapsed * 4));
		camUnderlay.zoom = FlxMath.lerp(1, camUnderlay.zoom, Math.exp(-elapsed * 4));
		playField.time = inst.time;
		super.update(elapsed);
	}

	function beatHit()
	{
		if (playField.conductor.curBeat % 4 == 0)
		{
			camHUD.zoom += 0.03;
			camUnderlay.zoom += 0.03;
		}
	}
}
