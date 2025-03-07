package funkin.states;

import haxe.Constraints;
import funkin.objects.gameplay.DialogueBox;
#if modchart
import modchart.Manager;
#end
import haxe.io.Path;
import funkin.modding.scripting.HscriptRuntime.HScriptRuntime;
import funkin.objects.Character;
import funkin.objects.gameplay.PlayField;

class PlayState extends MusicBeatState {
	public static var instance:PlayState;
	public static var daPixelZoom(default, null):Float = 6;
	public static var SONG:SongData;

	public var inst:FlxSound;
	public var ds:Bool = true;

	public var camUnderlay:FlxCamera;
	public var camHUD:FlxCamera;

	public var playField:PlayField;

	public static var isStoryMode:Bool = false;
	public static var weekDifficulty:String = "normal";
	public static var weekSongs:Array<String> = [];

	public var boyfriend:Character;
	public var dad:Character;
	public var girlfriend:Character;

	public var camFollow:FlxObject;
	public var curStage:String = "";
	public var defaultCamZoom:Null<Float> = 1;

	public var scripts:Array<HScriptRuntime> = [];

	override public function create() {
		super.create();
		instance = this;

		if (SONG == null)
			SONG = Song.parseSong();

		parseStage();

		var globalHXScripts = FileUtil.readDirectory("assets/scripts", 2).filter(function(ffe:String) {
			return ffe.contains(".hx");
		});
		var songHXScripts = FileUtil.readDirectory('assets/data/${SONG.song.toLowerCase().replace(" ", "-")}/', 3).filter(function(ffe:String) {
			return ffe.contains(".hx");
		});
		trace(globalHXScripts.length);

		for (i in 0...globalHXScripts.length) {
			var file = "assets/scripts/" + globalHXScripts[i];
			var doPush:Bool = !hsFileExists(file);

			if (doPush) {
				var script:HScriptRuntime = new HScriptRuntime(file);
				scripts.push(script);
			}
		}

		for (i in 0...songHXScripts.length) {
			var file = 'assets/data/${SONG.song.toLowerCase().replace(" ", "-")}/' + songHXScripts[i];
			var doPush:Bool = !hsFileExists(file);

			if (doPush) {
				var script:HScriptRuntime = new HScriptRuntime(file);
				scripts.push(script);
			}
		}

		call("onCreate");
		initChars();

		camHUD = new FlxCamera();
		camUnderlay = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camUnderlay.bgColor.alpha = 0;

		FlxG.cameras.add(camUnderlay, false);
		FlxG.cameras.add(camHUD, false);

		playField = new PlayField(SONG, controls);
		playField.cameras = [camHUD];
		uiGroup.add(playField);

		playField.iconP1.changeIcon(boyfriend.json.health_icon);
		playField.iconP2.changeIcon(dad.json.health_icon);

		playField.conductor.onBeatHit.add(beatHit);
		for (char in [boyfriend, dad, girlfriend])
			char.Conductor = playField.conductor;

		genSong(SONG.sections);
		add(uiGroup);

		inst = new FlxSound();
		inst.loadEmbedded(Paths.inst(SONG.song), false, false, endSong);

		#if modchart
		var modcharts:Manager = new Manager();
		add(modcharts);
		#end

		if (Assets.exists(Paths.voices(SONG.song))) {
			voices = new FlxSound();
			voices.loadEmbedded(Paths.voices(SONG.song));

			FlxG.sound.list.add(voices);
		}

		FlxG.sound.list.add(inst);
		playField.time = -playField.conductor.beatLength * 5;

		playField.oppHitSignal = function(note:Note, playAnim:Bool = true) {
			dad.confirmAnimation(note.data, playAnim);
			if (dad.hasAnimation(Character.singAnimations[note.data % Character.singAnimations.length] + "-alt")
				&& note.altNote
				&& playAnim)
				dad.playAnim(Character.singAnimations[note.data % Character.singAnimations.length] + "-alt", true);
		};
		playField.plrHitSignal = function(note:Note, playAnim:Bool = true) {
			boyfriend.confirmAnimation(note.data, playAnim);
			if (boyfriend.hasAnimation(Character.singAnimations[note.data % Character.singAnimations.length] + "-alt")
				&& note.altNote
				&& playAnim)
				boyfriend.playAnim(Character.singAnimations[note.data % Character.singAnimations.length] + "-alt", true);
		};

		playField.missCallback = function(id:Int = 0) {
			if (boyfriend.hasAnimation(Character.singAnimations[id % Character.singAnimations.length] + "miss"))
				boyfriend.playAnim(Character.singAnimations[id % Character.singAnimations.length] + "miss", true);
		}
		playField.conductor.onBeatHit.add(function() {
			stagesFunc(function(s:BaseStage) {
				s.curBeat = playField.conductor.curBeat;

				s.beatHit();
			});
		});
		playField.conductor.onStepHit.add(() -> call('onStepHit'));
		playField.conductor.onStepHit.add(stepHit);
		playField.conductor.mapBPMChanges(SONG);

		call("onCreatePost");
		stagesFunc((s)-> s.createPost());
		for (i in 0...100)
			update(1 / 60);

		startCallback();
	}

	public function stepHit() {
		stagesFunc(function(s:BaseStage) {
			s.curStep = playField.conductor.curStep;
			s.stepHit();
		});
	}

	dynamic public function startCallback() {
		new FlxTimer().start(0.1, function(e) {
			switch (Paths.formatSongName(SONG.song)) {
				case "senpai" | "roses":
					startDialogue(Paths.formatSongName(SONG.song), startCountdown);
				// startCountdown();
				default:
					startCountdown();
			}
		});
	}

	private var startingSong:Bool = false;
	var startedCountdown:Bool = false;

	public var camSPEED:Float = 1;
	public var stageJson:StageFile;

	function hsFileExists(scriptName:String) {
		var fileExists:Bool = false;

		for (i in 0...scripts.length) {
			if (scripts[i] != null && scripts[i].scriptName == scriptName)
				fileExists = true;
		}
		return fileExists;
	}

	function call(func:String, ?args:Array<Dynamic>)
		for (script in scripts)
			script.call(func, args != null ? args : []);

	function set(variable:String, value:Dynamic)
		for (script in scripts)
			script.set(variable, value);

	function parseStage() {
		// path ??= "stage";
		if (SONG.stage == null || SONG.stage.length < 1)
			SONG.stage = StageUtil.vanillaSongStage(Paths.formatSongName(SONG.song));

		curStage = SONG.stage;
		if (SONG.gfVersion == null || SONG.stage.length < 1)
			SONG.gfVersion = StageUtil.vanillaGF(SONG.stage);

		if (Assets.exists('assets/stages/$curStage.json'))
			stageJson = cast Json.parse(Assets.getText('assets/stages/$curStage.json'));
		else
			stageJson = cast Json.parse(Assets.getText('assets/stages/stage.json'));
		if (stageJson.defaultCamZoom != null)
			defaultCamZoom = stageJson.defaultCamZoom;
		if (stageJson.bfOffsets != null && stageJson.bfOffsets.length > 1) {
			BF_X = stageJson.bfOffsets[0];
			BF_Y = stageJson.bfOffsets[1];
		}
		if (stageJson.dadOffsets != null && stageJson.dadOffsets.length > 1) {
			DAD_X = stageJson.dadOffsets[0];
			DAD_Y = stageJson.dadOffsets[1];
		}
		if (stageJson.gfOffsets != null && stageJson.gfOffsets.length > 1) {
			GF_X = stageJson.gfOffsets[0];
			GF_X = stageJson.gfOffsets[1];
		}
		if (stageJson.cam_bf != null && stageJson.cam_bf.length > 1)
			boyfriendCameraOffset = stageJson.cam_bf;
		if (stageJson.cam_gf != null && stageJson.cam_gf.length > 1)
			girlfriendCameraOffset = stageJson.cam_gf;
		if (stageJson.cam_dad != null && stageJson.cam_dad.length > 1)
			opponentCameraOffset = stageJson.cam_dad;
		if (stageJson.camSPEED != null)
			camSPEED = stageJson.camSPEED;

		isPixelStage = stageJson.isPixel == true;

		startScriptNamed(curStage, "assets/stages/");

		switch curStage {
			case "stage":
				add(new funkin.objects.gameplay.stages.StageWeek1(this, true));
			case "glitchSchool":
				add(new funkin.objects.gameplay.stages.GlitchSchool(this, true));
			case "spooky":
				add(new funkin.objects.gameplay.stages.Spooky(this, true));
			case "school":
				add(new funkin.objects.gameplay.stages.School(this, true));
		}
	}

	function startScriptNamed(name:String = "", folder:String = "") {
		name += ".hx";
		var doPush:Bool = !hsFileExists(Path.addTrailingSlash(folder) + name) && Assets.exists(folder + name, TEXT);
		if (doPush) {
			var doodoo:HScriptRuntime = new HScriptRuntime(Path.addTrailingSlash(folder) + name);
			scripts.push(doodoo);
		}
	}

	public var BF_X:Float = 770;

	public static var isPixelStage:Bool = false;

	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	public var voices:FlxSound;

	inline function startCharacterPos(char:Character, ?gfCheck:Bool = false) {
		if (gfCheck && char.curCharacter.startsWith('gf')) { // IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
			char.danceEveryNumBeats = 2;
			girlfriend.kill();
		}
		char.x += char.position[0];
		char.y += char.position[1];
	}

	public var boyfriendCameraOffset:Array<Float> = [0, 0];
	public var opponentCameraOffset:Array<Float> = [0, 0];
	public var girlfriendCameraOffset:Array<Float> = [0, 0];

	function initChars() {
		boyfriend = new Character(SONG.player1, true);
		dad = new Character(SONG.player2);
		girlfriend = new Character(SONG.gfVersion);
		girlfriend.scrollFactor.set(0.95, 0.95);

		add(girlfriend);
		add(dad);
		add(boyfriend);
		boyfriend.setPosition(BF_X, BF_Y);
		girlfriend.setPosition(GF_X, GF_Y);
		dad.setPosition(DAD_X, DAD_Y);

		startCharacterPos(dad, true);
		startCharacterPos(boyfriend);
		startCharacterPos(girlfriend);

		var camPos:FlxPoint = FlxPoint.get(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);
		if (girlfriend != null) {
			camPos.x += girlfriend.getGraphicMidpoint().x + girlfriend.camera_position[0];
			camPos.y += girlfriend.getGraphicMidpoint().y + girlfriend.camera_position[1];
		}

		camFollow = new FlxObject();
		camFollow.setPosition(camPos.x, camPos.y);
		camPos.put();
		add(camFollow);
		FlxG.camera.follow(camFollow, LOCKON, 0.04);
		openfl.system.System.gc();
	}

	inline public function playerDance():Void {
		var anim:String = boyfriend.getAnimationName();
		if (boyfriend.holdTimer > playField.conductor.stepLength * (0.0011 #if FLX_PITCH / inst.pitch #end) * boyfriend.singDuration && anim.startsWith('sing'))
			boyfriend.dance();
	}

	inline public function characterBopper(beat:Int):Void {
		if (girlfriend != null
			&& beat % Math.round(1 * girlfriend.danceEveryNumBeats) == 0
			&& !girlfriend.getAnimationName().startsWith('sing')
			&& !girlfriend.stunned)
			girlfriend.dance();
		if (boyfriend != null
			&& beat % boyfriend.danceEveryNumBeats == 0
			&& !boyfriend.getAnimationName().startsWith('sing')
			&& !boyfriend.stunned)
			boyfriend.dance();
		if (dad != null && beat % dad.danceEveryNumBeats == 0 && !dad.getAnimationName().startsWith('sing') && !dad.stunned)
			dad.dance();

		if (!(controls.pressed.check(NOTE_LEFT) || controls.pressed.check(NOTE_DOWN) || controls.pressed.check(NOTE_UP) || controls.pressed.check(NOTE_RIGHT)))
			playerDance();
	}

	function genSong(sections:Array<Section>) {
		playField.notes.genSong(sections);
	}

	public var uiGroup:FlxTypedGroup<FlxBasic> = new FlxTypedGroup<FlxBasic>();

	override public function update(elapsed:Float) {
		camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, Math.exp(-elapsed * 4));
		camUnderlay.zoom = FlxMath.lerp(1, camUnderlay.zoom, Math.exp(-elapsed * 4));
		FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, Math.exp(-elapsed * 4));
		if (startedSong)
			playField.time = inst.time;

		if (startingSong && !startedSong) {
			if (startedCountdown) {
				playField.time += FlxG.elapsed * 1000;
				if (playField.time >= 0)
					startSong();
			}
		}
		call('onUpdate', [elapsed]);
		// add funny resync stuff:

		if (inst.playing && voices != null)
			if (Math.abs(voices.time - inst.time) > 20)
				voices.time = inst.time;

		super.update(elapsed);

		call('onUpdatePost', [elapsed]);
		if (controls.justPressed.UI_LEFT && controls.justPressed.UI_RESET) {
			inst.stop();
			if (voices != null)
				voices.stop();
			FlxG.switchState(new CharacterEditorState(SONG.player2));
		}
		if (controls.justPressed.CHART)
			FlxG.switchState(new ChartingState());
		if (playField.health == 0)
			FlxG.switchState(new GameOver());
	}

	public function new() {
		super();
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();
	}

	function startDialogue(song:String, finishCallback:Function) {
		if (!Assets.exists('assets/data/$song/dialogue.json') || !isStoryMode) {
			finishCallback();
			return;
		}

		var ds:DialogueFile = cast Json.parse(Assets.getText('assets/data/$song/dialogue.json'));
		var diabox:DialogueBox = new DialogueBox(ds, finishCallback);
		diabox.cameras = [camHUD];
		add(diabox);
	}

	inline function beatHit() {
		call('onBeatHit', []);

		characterBopper(playField.conductor.curBeat);
		if (playField.botplay)
			playerDance();

		if (playField.conductor.curBeat % 4 == 0) {
			camHUD.zoom += 0.04;
			camUnderlay.zoom += 0.04;
			FlxG.camera.zoom += 0.03;

			if (SONG.sections[Std.int(playField.conductor.curStep / 16)] != null)
				moveCameraSection();
		}
	}

	public function moveCameraSection(?sec:Null<Int>):Void {
		if (sec == null)
			sec = Std.int(playField.conductor.curStep / 16);
		if (sec < 0)
			sec = 0;

		if (SONG.sections[sec] == null)
			return;

		var isDad:Bool = (SONG.sections[sec].cameraFacePlayer != true);
		moveCamera(isDad);
	}

	public function moveCamera(isDad:Bool) {
		if (isDad) {
			if (dad == null)
				return;
			camFollow.setPosition(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
			camFollow.x += dad.camera_position[0] + opponentCameraOffset[0];
			camFollow.y += dad.camera_position[1] + opponentCameraOffset[1];
		} else {
			if (boyfriend == null)
				return;

			camFollow.setPosition(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
			camFollow.x -= boyfriend.camera_position[0] - boyfriendCameraOffset[0];
			camFollow.y += boyfriend.camera_position[1] + boyfriendCameraOffset[1];
		}
	}

	function startCountdown() {
		startedCountdown = true;
		startingSong = true;

		var swagCounter:Int = 0;

		startTimer = new FlxTimer().start(playField.conductor.beatLength / 1000, function(tmr:FlxTimer) {
			var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
			introAssets.set('default', ['ready', "set", "go"]);
			introAssets.set('school', ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel']);
			introAssets.set('schoolEvil', ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel']);

			var introAlts:Array<String> = introAssets.get('default');
			var altSuffix:String = "";

			if (stageJson.isPixel == true)
				introAlts = introAssets.get('school');

			switch (swagCounter) {
				case 0:
					FlxG.sound.play(Paths.sound('intro3' + altSuffix), 0.6);
				case 1:
					var ready:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[0]));
					ready.scrollFactor.set();
					ready.updateHitbox();

					if (curStage.startsWith('school'))
						ready.setGraphicSize(Std.int(ready.width * 6));

					ready.screenCenter();
					add(ready);
					FlxTween.tween(ready, {y: ready.y += 100, alpha: 0}, playField.conductor.beatLength / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween) {
							ready.kill();
							remove(ready, true);
							ready.destroy();
							ready = null;
						}
					});
					FlxG.sound.play(Paths.sound('intro2' + altSuffix), 0.6);
				case 2:
					var set:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[1]));
					set.scrollFactor.set();

					if (curStage.startsWith('school'))
						set.setGraphicSize(Std.int(set.width * daPixelZoom));

					set.screenCenter();
					add(set);
					FlxTween.tween(set, {y: set.y += 100, alpha: 0}, playField.conductor.beatLength / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween) {
							set.kill();
							remove(set, true);
							set.destroy();
							set = null;
						}
					});
					FlxG.sound.play(Paths.sound('intro1' + altSuffix), 0.6);
				case 3:
					var go:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[2]));
					go.scrollFactor.set();

					if (curStage.startsWith('school'))
						go.setGraphicSize(Std.int(go.width * daPixelZoom));

					go.updateHitbox();

					go.screenCenter();
					add(go);
					FlxTween.tween(go, {y: go.y += 100, alpha: 0}, playField.conductor.beatLength / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween) {
							go.kill();
							remove(go, true);
							go.destroy();
							go = null;
						}
					});
					FlxG.sound.play(Paths.sound('introGo' + altSuffix), 0.6);
				case 4:
			}

			swagCounter += 1;
			// generateSong('fresh');
		}, 5);
	}

	public var startedSong:Bool = false;

	public function startSong() {
		inst.play();
		startedSong = false;
		startedSong = true;
		if (voices != null)
			voices.play();
	}

	public function endSong() {
		weekSongs.remove(weekSongs[0]);

		if (!isStoryMode)
			FlxG.switchState(new Freeplay());
		else {
			if (weekSongs.length > 0) {
				SONG = Song.parseSong(Paths.formatSongName(weekSongs[0]), weekDifficulty.toLowerCase());
				FlxG.resetState();
			} else
				FlxG.switchState(new StoryMode());
		}
	}

	var startTimer:FlxTimer;
}

@:publicFields
class StageUtil {
	static function vanillaGF(s:String):String {
		trace(s);
		switch (s) {
			case "school":
				return "gf-pixel";
			case "schoolEvil":
				return "gf-pixel";
			case 'mall':
				return 'gf-christmas';
			case 'mallEvil':
				return 'gf-christmas';
			case 'spooky':
				return 'gf';
			case 'philly':
				return 'gf';
			case 'limo':
				return 'gf-car';
			case 'tank':
				return 'gf-tankman';
			default:
				return 'gf';
		}
		return 'gf';
	}

	public static function vanillaSongStage(songName):String {
		switch (songName) {
			case 'spookeez' | 'south' | 'monster':
				return 'spooky';
			case 'pico' | 'blammed' | 'philly' | 'philly-nice':
				return 'philly';
			case 'milf' | 'satin-panties' | 'high':
				return 'limo';
			case 'cocoa' | 'eggnog':
				return 'mall';
			case 'winter-horrorland':
				return 'mallEvil';
			case 'senpai' | 'roses':
				return 'school';
			case 'thorns':
				return 'schoolEvil';
			case 'ugh' | 'guns' | 'stress':
				return 'tank';
			default:
				return 'stage';
		}
		return 'stage';
	}
}
