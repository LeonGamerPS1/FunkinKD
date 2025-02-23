package funkin.objects;

import funkin.graphics.shaders.Pixel;

typedef CharacterData = {
	var name:String;
	var flipX:Null<Bool>;
	var texture_path:String;
	var health_icon:String;
	var health_colors:Array<Int>;
	var animations:Array<AnimationData>;
	var scale:Null<Float>;
	var dancer:Null<Bool>;
	var singDuration:Null<Float>;

	@:optional var camera_position:Array<Float>;
	@:optional var position:Array<Float>;

	@:optional var antialiasing:Null<Bool>;
	@:optional var pixelated:Null<Bool>;
}

typedef AnimationData = {
	var name:String;
	var prefix:String;
	var fps:Int;
	var looped:Bool;
	var x:Float;
	var y:Float;
	var indices:Array<Int>;
}

@:hscript({
	context: [Std, Math] // Std and Math will be included in all scripts.
})
class Character extends FlxSprite {
	private var offsetMap:Map<String, Array<Float>> = new Map<String, Array<Float>>();

	public var singDuration:Float = 6;

	public var holdTimer:Float = 0;

	public var json:CharacterData;
	public var dancer(default, default):Bool = false;
	public var isPlayer:Bool = false;
	public var curCharacter:String = "bf";
	public var animationNotes:Array<Dynamic> = [];
	public var danceIdle:Bool = false;
	public var idleSuffix:String = "";
	public var stunned:Bool = false;

	public var position:Array<Float> = [0, 0];
	public var camera_position:Array<Float> = [0, 0];
	public var health_colors:Array<Int> = [0, 0, 0];
	public var Conductor:Conductor;

	public function new(charName:String = "dad", isPlayer:Bool = false) {
		super(0, 0);
		this.isPlayer = isPlayer;
		curCharacter = charName;

		if (Assets.exists('assets/characters/$charName.json'))
			json = parseShit('assets/characters/$charName.json');
		else
			json = fallback();

		if (json.dancer != null)
			dancer = json.dancer;
		if (json.health_colors != null)
			health_colors = json.health_colors;
		if (json.singDuration != null)
			singDuration = json.singDuration;
		if (json.position != null)
			position = json.position;
		if (json.camera_position != null)
			camera_position = json.camera_position;

		loadTexture('characters/${json.texture_path}');
		regenOffsets(isPlayer);
		if (FlxG.save.data.characters == false)
			kill();
		//	trace(json.health_colors);
	}

	public var danceEveryNumBeats:Int = 1;

	private var settingCharacterUp:Bool = true;

	public function recalculateDanceIdle() {
		var lastDanceIdle:Bool = danceIdle;
		danceIdle = (hasAnimation('danceLeft' + idleSuffix) && hasAnimation('danceRight' + idleSuffix));

		if (settingCharacterUp) {
			danceEveryNumBeats = (danceIdle ? 1 : 2);
		} else if (lastDanceIdle != danceIdle) {
			var calc:Float = danceEveryNumBeats;
			if (danceIdle)
				calc /= 2;
			else
				calc *= 2;

			danceEveryNumBeats = Math.round(Math.max(calc, 1));
		}
		settingCharacterUp = false;
	}

	function loadTexture(s:String = "") {
		var tex = Paths.getAtlas(s);
		frames = tex;
	}

	function regenOffsets(isPlayer:Bool = false) {
		if (json == null)
			return;

		if (json.scale != null)
			scale.set(json.scale, json.scale);
		if (json.flipX != null)
			flipX = (json.flipX != isPlayer);
		if (json.antialiasing == null)
			json.antialiasing = true; // makes it antialias if the character json doesn't specify wether it should or not

		antialiasing = json.antialiasing;

		if (json.position != null)
			origin.set(json.position[0] - width / 2, json.position[1] - height);
		updateHitbox();

		curCharacter = json.name;
		trace('Loading ${json.animations.length} Animations for $curCharacter');
		for (i in 0...json.animations.length) {
			var animationMeta = json.animations[i];
			if (animationMeta.indices != null && animationMeta.indices.length > 0)
				animation.addByIndices(animationMeta.name, animationMeta.prefix, animationMeta.indices, "", 24, animationMeta.looped);
			else
				animation.addByPrefix(animationMeta.name, animationMeta.prefix, animationMeta.fps, animationMeta.looped);
			offsetMap[animationMeta.name] = [animationMeta.x, animationMeta.y];
			playAnim(animationMeta.name, true);
		}
		playAnim('idle');
	}

	public function playAnim(name:String, force:Bool = false, reversed:Bool = false, frame:Int = 0) {
		if (hasAnimation(name))
			animation.play(name, force, reversed, frame);
		_lastPlayedAnimation = name;

		if (offsetMap.exists(name))
			offset.set(offsetMap[name][0], offsetMap[name][1]);

		if (curCharacter.startsWith('gf-') || curCharacter == 'gf') {
			if (name == 'singLEFT')
				danced = true;
			else if (name == 'singRIGHT')
				danced = false;

			if (name == 'singUP' || name == 'singDOWN')
				danced = !danced;
		}
	}

	function parseShit(path:String):CharacterData {
		var rawJson = Assets.getText(path);

		var jsonData:CharacterData = Json.parse(rawJson);
		return cast jsonData;
	}

	function fallback():CharacterData {
		return cast Json.parse(Assets.getText('assets/characters/dad.json'));
	}

	private var danced:Bool = false;

	/**
	 * FOR GF DANCING SHIT
	 */
	@:hscript
	public function dance() {
		if (dancer) {
			danced = !danced;

			if (danced)
				playAnim('danceRight');
			else
				playAnim('danceLeft');
			return;
		}

		playAnim('idle');
	}

	inline public function isAnimationNull():Bool {
		return (animation.curAnim == null);
	}

	var _lastPlayedAnimation:String;

	inline public function getAnimationName():String {
		return _lastPlayedAnimation;
	}

	public function isAnimationFinished():Bool {
		if (isAnimationNull())
			return false;
		return animation.curAnim.finished;
	}

	public function finishAnimation():Void {
		if (isAnimationNull())
			return;

		animation.curAnim.finish();
	}

	public function hasAnimation(anim:String):Bool {
		return offsetMap.exists(anim);
	}

	override function update(elapsed:Float) {
		switch (curCharacter) {
			case 'pico-speaker':
				if (animationNotes.length > 0 && Conductor.songPosition > animationNotes[0][0]) {
					var noteData:Int = 1;
					if (animationNotes[0][1] > 2)
						noteData = 3;

					noteData += FlxG.random.int(0, 1);
					playAnim('shoot' + noteData, true);
					animationNotes.shift();
				}
				if (isAnimationFinished())
					playAnim(getAnimationName(), false, false, animation.curAnim.frames.length - 3);
		}

		if (getAnimationName().startsWith('sing'))
			holdTimer += elapsed;
		else if (isPlayer)
			holdTimer = 0;

		if (Conductor != null) {
			if (!isPlayer
				&& holdTimer >= Conductor.stepLength * (0.0011 #if FLX_PITCH / (FlxG.sound.music != null ? FlxG.sound.music.pitch : 1) #end) * singDuration) {
				dance();
				holdTimer = 0;
			}
		}

		var name:String = getAnimationName();
		if (isAnimationFinished() && hasAnimation('$name-loop'))
			playAnim('$name-loop');

		super.update(elapsed);
	}

	public static var singAnimations = ["singLEFT", "singDOWN", "singUP", "singRIGHT"];

	public function confirmAnimation(data:Int, ?playAnim:Bool = true) {
		if (hasAnimation(singAnimations[data]) && playAnim)
			this.playAnim(singAnimations[data], true);
		holdTimer = 0;
	}
}
