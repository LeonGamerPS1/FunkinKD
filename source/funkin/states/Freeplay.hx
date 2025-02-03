package funkin.states;

import flixel.text.FlxText;
import lime.app.Application;
import flixel.effects.FlxFlicker;
import funkin.backend.WeekFile.WSongMeta;
import flixel.group.FlxSpriteGroup;
import funkin.objects.HealthIcon;
import funkin.objects.Alphabet;

class Weekbet extends Alphabet {
	public var week:WeekFile;
	public var song:WSongMeta;

	override function destroy() {
		week = null;
		song = null;
		super.destroy();
	}
}

class Freeplay extends MusicBeatState {
	var weeks:Array<WeekFile> = [];

	var items:FlxTypedGroup<Weekbet> = new FlxTypedGroup();
	var icons:FlxTypedGroup<HealthIcon> = new FlxTypedGroup();
	var curSel:Int = 0;
	var curDiff:String;

	var camFollow:FlxObject;
	var curSelected(get, null):Weekbet;

	var selSom:Bool = false;
	var funkyCam:FlxCamera = new FlxCamera();
	var bg:FlxSprite;
	var selectionInfo:FlxSpriteGroup;
	var text:FlxText;
	var DcurSel:Int = 0;

	override function create():Void {
		super.create();
		WeekData.reload();

		FlxG.cameras.add(funkyCam, false);
		funkyCam.bgColor.alpha = 0;

		for (key => value in WeekData.weeks)
			weeks.push(value);
		curDiff = weeks[0].difficulties[1 % weeks[0].difficulties.length];
		weeks.sort(function(w1, w2) {
			return w1.order - w2.order;
		});

		bg = new FlxSprite(-80).loadGraphic(Paths.image('menu/menuDesat'));
		bg.scrollFactor.set(0, 0);
		bg.setGraphicSize();
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = FlxG.save.data.antialias;
		add(bg);

		var i:Null<Int> = 0;
		for (week in weeks) {
			for (song in week.songs) {
				var item:Weekbet = new Weekbet(0, 0, song.name, true);
				item.week = week;
				item.x = 30 + (4 * i);
				item.y += (160 * i);
				item.song = song;
				items.add(item);

				var icon:HealthIcon = new HealthIcon(song.freeplayIcon);
				icon.sprTracker = item;
				icon.scrollFactor.set(1, 1);
				icons.add(icon);
				i++;
			}
		}
		i = null;

		add(items);
		add(icons);

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollow.screenCenter();
		FlxG.camera.follow(camFollow, FlxCameraFollowStyle.LOCKON);
		changeSel();

		selectionInfo = new FlxSpriteGroup(0, 0);
		selectionInfo.cameras = [funkyCam];
		add(selectionInfo);
		var back:FlxSprite = new FlxSprite().makeGraphic(FlxG.width + 1 /**it is one pixel short lols thats why + 1**/, 50, FlxColor.BLACK);
		back.alpha = 0.8;
		back.updateHitbox();
		selectionInfo.add(back);

		text = new FlxText(10, 20, 0, 'Week: ${curSelected.week.displayText}, Diff: $curDiff, Song: ${curSelected.song.name}');
		text.setFormat(Paths.font("vcr"), 14, FlxColor.WHITE, OUTLINE, FlxColor.BLACK);
		text.borderSize = 2;
		selectionInfo.add(text);
	}

	override function update(elapsed:Float):Void {
		text.text = ' Song: ${curSelected.song.name}, Diff: $curDiff';
		super.update(elapsed);

		if (curSelected != null)
			camFollow.y = FlxMath.lerp(curSelected.y, camFollow.y, 0.88);
		if (controls.justPressed.UI_DOWN && !selSom)
			changeSel(1);
		if (controls.justPressed.UI_UP && !selSom)
			changeSel(-1);
		if (controls.justPressed.UI_LEFT && !selSom)
			changeSelD(-1);
		if (controls.justPressed.UI_RIGHT && !selSom)
			changeSelD(1);

		if (DcurSel > curSelected.week.difficulties.length - 1)
			DcurSel = 0;
		if (DcurSel < 0)
			DcurSel = curSelected.week.difficulties.length - 1;
		
		curDiff = curSelected.week.difficulties[DcurSel];

		if (controls.justPressed.UI_BACK) {
			selSom = true;
			FlxG.sound.play(Paths.sound('cancelMenu'));
			funkyCam.kill();
			FlxG.cameras.remove(funkyCam, true);

			FlxG.switchState(MainMenu.new);
		}

		if (controls.justPressed.UI_ACCEPT && !selSom) {
			selSom = true;
			FlxG.sound.play(Paths.sound('confirmMenu'));
			FlxFlicker.flicker(curSelected, 1, 0.08, true, true, function(flick) {
				try {
					var parsedSongName:String = Paths.formatSongName(curSelected.text);
					PlayState.SONG = Song.parseSong(parsedSongName, curDiff.toLowerCase());
					for (i in 0...items.length) {
						FlxTween.tween(items.members[i].offset, {x: items.members[i].width}, 0.9);
					}
					new FlxTimer().start(1, (e) -> FlxG.switchState(PlayState.new));
				} catch (e:Dynamic) {
					Application.current.window.alert("The game has failed Loading the song '" + curSelected.text + '.\n Error Info: $e ', "Error");
					selSom = false;
				}
			});
		}

		for (i in 0...items.length) {
			var item = items.members[i];
			item.alpha = item == curSelected ? 1 : 0.5;
		}
	}

	function changeSelD(i:Int = 0) {
		DcurSel += i;
		if (DcurSel > curSelected.week.difficulties.length - 1)
			DcurSel = 0;
		if (DcurSel < 0)
			DcurSel = curSelected.week.difficulties.length - 1;

		curDiff = curSelected.week.difficulties[DcurSel];
	}

	function changeSel(i:Int = 0) {
		curSel += i;
		FlxG.sound.play(Paths.sound('scrollMenu'));
		if (curSel < 0)
			curSel = items.members.length - 1;
		if (curSel > items.members.length - 1)
			curSel = 0;
		FlxTween.cancelTweensOf(bg);
		FlxTween.color(bg, 0.4, bg.color, FlxColor.fromRGB(get_currentSong().color[0], get_currentSong().color[1], get_currentSong().color[2], 255));
	}

	function get_curSelected():Weekbet {
		return items.members[curSel];
	}

	function get_currentWeek():WeekFile {
		return curSelected.week;
	}

	function get_currentSong():WSongMeta {
		return curSelected.song;
	}
}
