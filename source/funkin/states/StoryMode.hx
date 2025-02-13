package funkin.states;

import funkin.backend.WeekFile.WSongMeta;
import flixel.text.FlxText;
import flixel.group.FlxGroup;

class StoryMode extends BaseState
{
	var bg:FlxSprite;

	var difficultySelectors:FlxGroup;
	var sprDifficulty:FlxSprite;
	var leftArrow:FlxSprite;
	var rightArrow:FlxSprite;
	var grpWeekText:FlxTypedGroup<MenuItem>;
	var txtTracklist:FlxText;

	public var curSel:Int = 0;

	function changeSel(add:Int = 0)
	{
		txtTracklist.text = "Tracks";
		curSel += add;
		FlxG.sound.play(Paths.sound('scrollMenu'));
		if (curSel < 0)
			curSel = grpWeekText.members.length - 1;
		if (curSel > grpWeekText.members.length - 1)
			curSel = 0;
		var bullShit:Int = 0;

		for (item in grpWeekText.members)
		{
			item.targetY = bullShit - curSel;

			bullShit++;

			item.alpha = 0.6;
			// item.setGraphicSize(Std.int(item.width * 0.8));

			if (item.targetY == 0)
				item.alpha = 1;
		}
		txtTracklist.text += arrayToNewLines(get_curSelected().week.songs);


	}

	function arrayToNewLines(arr:Array<WSongMeta>)
	{
		var string = "\n";

		for (i in 0...arr.length)
			string += "\n" + arr[i].name;

		return string;
	}

	function get_curSelected()
	{
		return grpWeekText.members[curSel];
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (controls.justPressed.UI_DOWN)
			changeSel(1);
		if (controls.justPressed.UI_UP)
			changeSel(-1);

        if(controls.justPressed.UI_ACCEPT)
        {
            var songArray:Array<WSongMeta> = get_curSelected().week.songs;
            var arrayOfStrings:Array<String> = [];
            for (index => value in songArray) {
                arrayOfStrings.push(value.name);
            }
            PlayState.weekSongs = arrayOfStrings;
            PlayState.isStoryMode = true;
            PlayState.SONG = Song.parseSong(Paths.formatSongName(PlayState.weekSongs[0]));
            FlxG.switchState(new PlayState());
        }
	}

	override function create()
	{
		super.create();

		var ui_tex = Paths.getSparrowAtlas("campaign_menu_UI_assets");

		bg = new FlxSprite(0, 56).makeGraphic(FlxG.width, 400, 0xFFF9CF51);

		difficultySelectors = new FlxGroup();
		add(difficultySelectors);

		grpWeekText = new FlxTypedGroup<MenuItem>();
		add(grpWeekText);
		add(bg);

		regenWeeks();

		leftArrow = new FlxSprite(grpWeekText.members[0].x + grpWeekText.members[0].width + 10, grpWeekText.members[0].y + 10);
		leftArrow.frames = ui_tex;
		leftArrow.animation.addByPrefix('idle', "arrow left");
		leftArrow.animation.addByPrefix('press', "arrow push left");
		leftArrow.animation.play('idle');
		difficultySelectors.add(leftArrow);

		sprDifficulty = new FlxSprite(leftArrow.x + 130, leftArrow.y);
		sprDifficulty.frames = ui_tex;
		sprDifficulty.animation.addByPrefix('easy', 'EASY');
		sprDifficulty.animation.addByPrefix('normal', 'NORMAL');
		sprDifficulty.animation.addByPrefix('hard', 'HARD');
		sprDifficulty.animation.play('easy');

		rightArrow = new FlxSprite(sprDifficulty.x + sprDifficulty.width + 50, leftArrow.y);
		rightArrow.frames = ui_tex;
		rightArrow.animation.addByPrefix('idle', 'arrow right');
		rightArrow.animation.addByPrefix('press', "arrow push right", 24, false);
		rightArrow.animation.play('idle');
		difficultySelectors.add(rightArrow);

		txtTracklist = new FlxText(FlxG.width * 0.05, bg.x + bg.height + 100, 0, "Tracks", 32);
		txtTracklist.setFormat(null,32,FlxColor.WHITE,LEFT);
		txtTracklist.font = Paths.font("vcr");
		txtTracklist.color = 0xFFe55777;
		add(txtTracklist);

		difficultySelectors.add(sprDifficulty);

		changeSel();
		for (i in 0...100)
			update(1 / 60);
	}

	function regenWeeks()
	{
		WeekData.reload();
		var i = 0;
		var weeks = [];
		for (key => value in WeekData.weeks)
			weeks.push(value);
		weeks.sort(function(w1, w2)
		{
			return w1.order - w2.order;
		});

		for (week in weeks)
		{
			var menuitem:MenuItem = new MenuItem(week);
			menuitem.y = bg.y + bg.height + (100 + (160 * i));
			grpWeekText.add(menuitem);
			menuitem.yAdd = 180;
			i++;
		}
	}
}

class MenuItem extends FlxSprite
{
	public var week:WeekFile;
	public var targetY:Float = 0;
	public var yMult:Float = 120;
	public var xAdd:Float = 0;
	public var yAdd:Float = 0;
	public var forceX:Float = Math.NEGATIVE_INFINITY;

	public function new(week:WeekFile)
	{
		super();
		this.week = week;

		trace(week.weekImage);
		loadGraphic(Paths.image('weeks/${week.weekImage}'));
		screenCenter();
		antialiasing = true;
		forceX = (FlxG.width - width) / 2;
	}

	override function update(elapsed:Float):Void
	{
		var scaledY = FlxMath.remapToRange(targetY, 0, 1, 0, 1.3);

		var lerpVal:Float = CoolUtil.boundTo(elapsed * 9.6, 0, 1);
		y = FlxMath.lerp(y, (scaledY * yMult) + (FlxG.height * 0.48) + yAdd, lerpVal);
		if (forceX != Math.NEGATIVE_INFINITY)
		{
			x = forceX;
		}
		else
		{
			x = FlxMath.lerp(x, (targetY * 20) + 90 + xAdd, lerpVal);
		}
		super.update(elapsed);
	}
}
