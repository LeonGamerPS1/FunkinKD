package funkin.states;

class Title extends MusicBeatState
{
	public var fatRamEater:FlxSprite;
	public var titleText:FlxSprite;
	public var logoBl:FlxSprite;
	public var fuckingtomain:Bool = false;

	var conductor:Conductor = new Conductor(102);

	public override function create()
	{
		conductor.onBeatHit.add(beatHit);
		add(conductor);
		FlxG.sound.playMusic(Paths.sound('freakyMenu'));

		fatRamEater = new FlxSprite(FlxG.width * 0.4, FlxG.height * 0.07);
		fatRamEater.frames = Paths.getSparrowAtlas('title/gfDanceTitle');
		fatRamEater.animation.addByIndices('danceLeft', 'gfDance', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
		fatRamEater.animation.addByIndices('danceRight', 'gfDance', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
		fatRamEater.antialiasing = true;
		fatRamEater.animation.play('danceRight');
		add(fatRamEater);

		titleText = new FlxSprite(100, FlxG.height * 0.8);
		titleText.frames = Paths.getSparrowAtlas('title/titleEnter');
		titleText.animation.addByPrefix('idle', "Press Enter to Begin", 24);
		titleText.animation.addByPrefix('press', "ENTER PRESSED", 24);
		titleText.antialiasing = true;
		titleText.animation.play('idle');
		titleText.updateHitbox();
		// titleText.screenCenter(X);
		add(titleText);

		logoBl = new FlxSprite(-150, -100);
		logoBl.frames = Paths.getSparrowAtlas('title/logoBumpin');
		logoBl.antialiasing = true;
		logoBl.animation.addByPrefix('bump', 'logo bumpin', 24);
		logoBl.animation.play('bump');
		logoBl.updateHitbox();
		add(logoBl);

		super.create();
		FlxG.camera.flash();
	}

	public var danceLeft(get, null):Bool;

	function get_danceLeft():Bool
	{
		return (conductor.curBeat % 2 == 0);
	}

	function beatHit()
	{
		logoBl.animation.play('bump', true);

		if (danceLeft)
			fatRamEater.animation.play('danceLeft', true);
		else
			fatRamEater.animation.play('danceRight', true);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
        conductor.songPosition = FlxG.sound.music.time;
		var pressedEnter:Bool = (controls.justPressed.UI_ACCEPT);

		if (pressedEnter && !fuckingtomain)
		{
			fuckingtomain = true;
			yay();
		}
	}

	function yay()
	{
		FlxG.camera.flash(FlxColor.WHITE, 1, null, true);
		FlxG.sound.play(Paths.sound('confirmMenu'), 1);
		titleText.animation.play('press');
		new FlxTimer().start(1, function(tmr:FlxTimer)
		{
			tmr.cancel();
			if (tmr != null)
				tmr.destroy();
			FlxG.switchState(new MainMenu());
		});
	}
}
