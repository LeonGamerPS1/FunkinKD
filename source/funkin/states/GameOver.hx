package funkin.states;

import funkin.objects.Character;

class GameOver extends BaseState
{
	var boyfriend:Character;

	var gameOverMusic:String;
	var gameOverEnd:String;
	var gameOverStart:String;
	var gameOverSound:FlxSound;

	var pressed = false;

	override function create()
	{
		super.create();

		gameOverMusic = getPrefixOf("gameOver");
		gameOverEnd = getPrefixOf("gameOverEnd");
		gameOverStart = getPrefixOf("fnf_loss_sfx");

		gameOverSound = FlxG.sound.load(Paths.music(gameOverStart));
		gameOverSound.play();
		gameOverSound.onComplete = startMusic;

		boyfriend = new Character(getPrefixOf("bf-dead"), true);
		add(boyfriend);
		boyfriend.playAnim("firstDeath", true);
		boyfriend.screenCenter();
		startCharacterPos(boyfriend);
	}

	inline function startCharacterPos(char:Character)
	{
		char.x += char.position[0];
		char.y += char.position[1];
	}

	function startMusic()
	{
		gameOverSound = FlxG.sound.load(Paths.music(gameOverMusic), 1, true);
		gameOverSound.play();
		boyfriend.playAnim("deathLoop", true);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (controls.justPressed.UI_ACCEPT)
			retry();
	}

	inline function retry()
	{
		if (pressed)
			return;
		boyfriend.playAnim("deathConfirm", true);
		pressed = true;
		gameOverSound.stop();
		gameOverSound.destroy();
		gameOverSound = null;

		var sound = FlxG.sound.play(Paths.music(gameOverEnd), 1, true, null, true, function()
		{
			FlxG.switchState(new PlayState());
		});
		FlxG.camera.fade(FlxColor.BLACK, sound.length / 1000);
	}

	inline function getPrefixOf(s:String)
		return s + (PlayState.isPixelStage ? "-pixel" : "");
}
