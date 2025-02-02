package funkin.states;

import funkin.objects.Character;
import funkin.objects.gameplay.PlayField;

class PlayState extends MusicBeatState {
	public static var daPixelZoom(default, null):Float = 6;
	public static var SONG:SongData;

	public var inst:FlxSound;
	public var ds:Bool = true;

	public var camUnderlay:FlxCamera;
	public var camHUD:FlxCamera;

	public var playField:PlayField;

	public var boyfriend:Character;
	public var dad:Character;
	public var girlfriend:Character;

	public var camFollow:FlxObject;
	public var curStage:String = "";
	public var defaultCamZoom:Null<Float> = 1;

	override public function create() {
		if (SONG == null)
			SONG = Song.parseSong();

		parseStage();
		initChars();

		camHUD = new FlxCamera();
		camUnderlay = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camUnderlay.bgColor.alpha = 0;
		bgColor = FlxColor.GRAY;

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

		super.create();

		genSong(SONG.sections);
		add(uiGroup);

		inst = new FlxSound();
		inst.loadEmbedded(Paths.inst(SONG.song));

		if (Assets.exists(Paths.voices(SONG.song))) {
			voices = new FlxSound();
			voices.loadEmbedded(Paths.voices(SONG.song));

			FlxG.sound.list.add(voices);
		}

		FlxG.sound.list.add(inst);
		playField.time = -playField.conductor.beatLength * 5;

		playField.oppHitSignal = dad.confirmAnimation;
		playField.plrHitSignal = boyfriend.confirmAnimation;

		playField.missCallback = function(id:Int = 0) {
			if (boyfriend.hasAnimation(Character.singAnimations[id % Character.singAnimations.length] + "miss"))
				boyfriend.playAnim(Character.singAnimations[id % Character.singAnimations.length] + "miss", true);
		}
		playField.conductor.onBeatHit.add(function() {
			stagesFunc(function(s:BaseStage) {
				s.beatHit();
			});
		});
		playField.conductor.mapBPMChanges(SONG);
		startCountdown();
	}

	private var startingSong:Bool = false;
	var startedCountdown:Bool = false;

	public var camSPEED:Float = 1;
	public var stageJson:StageFile;

	function parseStage() {
		// path ??= "stage";
		if (SONG.stage == null || SONG.stage.length < 1)
			SONG.stage = StageUtil.vanillaSongStage(Paths.formatSongName(SONG.song));
		if (SONG.stage == null || SONG.stage.length < 1)
			SONG.gfVersion = StageUtil.vanillaGF(SONG.stage);
		curStage = SONG.stage;

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

		switch curStage.toLowerCase() {
			case "stage":
				add(new funkin.objects.gameplay.stages.StageWeek1(this, true));
			case "school":
				add(new funkin.objects.gameplay.stages.School(this, true));
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

	function startCharacterPos(char:Character, ?gfCheck:Bool = false) {
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

	public function playerDance():Void {
		var anim:String = boyfriend.getAnimationName();
		if (boyfriend.holdTimer > playField.conductor.stepLength * (0.0011 #if FLX_PITCH / inst.pitch #end) * boyfriend.singDuration && anim.startsWith('sing'))
			boyfriend.dance();
	}

	public function characterBopper(beat:Int):Void {
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

		// add funny resync stuff:

		if (inst.playing && voices != null)
			if (Math.abs(voices.time - inst.time) > 20)
				voices.time = inst.time;
		super.update(elapsed);
		if (controls.justPressed.UI_LEFT && controls.justPressed.NOTE_DOWN) {
			inst.stop();
			if (voices != null)
				voices.stop();
			FlxG.switchState(new CharacterEditorState(SONG.player2));
		}
	}

	public function new() {
		super();
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();
	}

	function beatHit() {
		characterBopper(playField.conductor.curBeat);

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
			dad.dance();
			girlfriend.dance();
			boyfriend.playAnim('idle');

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
							ready.destroy();
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
							set.destroy();
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
							go.destroy();
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

	var startTimer:FlxTimer;
}

@:publicFields
class StageUtil {
	static function vanillaGF(s:String):String {
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
		}
		return 'stage';
	}
}
