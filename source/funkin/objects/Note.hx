package funkin.objects;

class Note extends FlxSprite {
	public static var noteScale(default, null):Float = 0.7;
	public static var directions:Array<String> = ["purple", "blue", "green", "red"];

	public var texture(default, set):String;
	public var isPixel:Bool = false;

	public var data:Int = 0;
	public var time:Float = 0;
	public var mustHit:Bool = false;
	public var wasHit:Bool = false;
	public var wasGoodHit:Bool = false;

	public var scrollSpeed:Float = 1;
	public var length:Float = 500 / 1000;

	public var downscroll:Bool = false;
	public var prevNote:Note;
	public var strum:StrumNote;
	public var conductor:Conductor;
	public var offsetX:Float = 0;
	public var ignoreNote:Bool = false;

	public var parent:Note;

	public static var swagWidth:Float = 160 * 0.7;

	public var altNote:Bool = false;

	public var wasMissed:Bool = false;
	public var multSpeed:Float = 1;
	public var sustain:Sustain;
	public var rating:String = "?";
	public var noteType(default, set):String = "";

	public var extraData:Map<String, Dynamic> = [];

	public function canBeHit(conductor:Conductor):Bool {
		if (mustHit
			&& time > conductor.songPosition - (Conductor.safeZoneOffset)
			&& time < conductor.songPosition + (Conductor.safeZoneOffset))
			return true;
		else
			return false;
	}

	public function new(time:Float = 0, data:Int = 0, ?isPixel:Bool = false, ?prevNote:Note, ?sustainSpeed:Float = 1, ?conductor:Conductor,
			nt:String = "normal") {
		super(0, -2000);

		this.data = data;
		this.isPixel = isPixel;
		this.time = time;
		this.prevNote = prevNote;
		this.conductor = conductor;
		texture = "notes";

		colorSwap = new ColorSwap();
		shader = colorSwap.shader;
		noteType = nt;
		if (!isSustainNote)
			playAnim("arrow");
	}

	public function playAnim(s:String, force:Bool = false) {
		animation.play(s, force);
		centerOffsets();
		centerOrigin();
	}

	public var hitCausesMiss:Bool = false;

	function reloadNote(tex:String = "notes", isPixel:Bool, ?sustainSpeed:Float = 1) {
		tex ??= "notes";
		if (PlayState.SONG.skin != null && PlayState.SONG.skin != "")
			tex = PlayState.SONG.skin;
		this.isPixel = isPixel;
		var prefix = isPixel ? "pixel/" : "";
		var path = Paths.img('noteSkins/$prefix$tex');

		if (!Assets.exists(path)) {
			trace(' "$path" doesnt exist, Reverting skin back to default');
			tex = "notes";
		}
		@:bypassAccessor
		texture = tex;

		if (!isPixel)
			loadDefaultNoteAnims(tex, sustainSpeed);
		else
			loadPixelNoteAnimations(tex, sustainSpeed);
	}

	var canDrawSustain:Bool = false;

	override function update(elapsed:Float) {
		if (!mustHit) {
			if (time <= conductor.songPosition)
				wasGoodHit = true;
		} else {
			if (!wasGoodHit && time <= conductor.songPosition + 50)
				if (!isSustainNote || (prevNote.wasGoodHit && !ignoreNote))
					botHit = true;
		}
		super.update(elapsed);
	}

	public var botHit = false;

	function loadPixelNoteAnimations(tex:String, ?sustainSpeed:Float = 1) {
		if (!isSustainNote) {
			loadGraphic(Paths.image('noteSkins/pixel/$tex'), true, 17, 17);

			animation.add('arrow', [data % 4 + 4], 12, false);
			setGraphicSize(width * 6);

			antialiasing = false;
			updateHitbox();
		} else {
			loadGraphic(Paths.image('noteSkins/pixel/${tex}ENDS'));
			width = width / 4;
			height = height / 5;
			loadGraphic(Paths.image('noteSkins/pixel/${tex}ENDS'), true, 7, 6);

			animation.add('hold', [data], 12, false);
			animation.add('end', [data + 4], 12, false);
			setGraphicSize(width * 6);
			playAnim("end");
			updateHitbox();

			if (prevNote != null && prevNote.isSustainNote) {
				prevNote.playAnim("hold");
				prevNote.scale.y = 6 * (conductor.stepLength / 100 * 1.5 * sustainSpeed);
				prevNote.updateHitbox();
			}
		}
	}

	public var inEditor:Bool = false;

	override function draw() {
		if ((!wasGoodHit || !wasHit) || inEditor)
			super.draw();
	}

	function loadDefaultNoteAnims(tex:String, ?sustainSpeed:Float = 1) {
		frames = Paths.getAtlas('noteSkins/$tex');

		animation.addByPrefix('arrow', '${directions[data % directions.length]}0', 24, false);
		animation.addByPrefix('hold', '${directions[data % directions.length]} hold piece', 24, false);
		animation.addByPrefix('end', '${directions[data % directions.length]} hold end', 24, false);

		setGraphicSize(width * 0.7);
		updateHitbox();

		if (isSustainNote && prevNote != null) {
			playAnim('end');
			scale.y = 1;
			updateHitbox();
			if (prevNote != null && prevNote.isSustainNote) {
				prevNote.playAnim('hold');
				prevNote.scale.y = 0.7 * (conductor.stepLength / 100 * 1.5 * sustainSpeed);
				prevNote.updateHitbox();
				prevNote.antialiasing = false;
			}
		}

		antialiasing = true;
	}

	function set_texture(value:String):String {
		texture = value;

		reloadNote(value, isPixel);
		return texture = value;
	}

	public var offsetY:Float = 0;
	public var multAlpha:Float = 1;

	public var distance:Float = 3000;
	public var colorSwap:ColorSwap;

	public var copyX:Null<Bool> = true;
	public var copyY:Null<Bool> = true;
	public var copyAngle:Null<Bool> = true;
	public var copyAlpha:Null<Bool> = true;
	public var isSustainNote:Bool = false;

	public var noteSplashHue:Float = 0;
	public var noteSplashSat:Float = 0;
	public var noteSplashBrt:Float = 0;

	public function followStrumNote(myStrum:StrumNote, conductor:Conductor, ?songSpeed:Float = 1) {
		this.strum = myStrum;

		scrollSpeed = FlxMath.roundDecimal(scrollSpeed * multSpeed, 2);

		var strumX:Float = myStrum.x;
		var strumY:Float = myStrum.y;
		var strumAngle:Float = myStrum.angle;
		var strumAlpha:Float = myStrum.alpha;
		var strumDirection:Float = myStrum.direction;

		distance = Math.floor((0.45 * (conductor.songPosition - time) * songSpeed * multSpeed));

		if (!myStrum.downScroll)
			distance *= -1;

		var angleDir = strumDirection * Math.PI / 180;

		if (copyAlpha)
			alpha = strumAlpha * multAlpha;

		if (copyX)
			x = strumX + offsetX + Math.cos(angleDir) * distance;
		if (isSustainNote)
			x = strumX + (strum.width / 2) - (width / 2) + Math.cos(angleDir) * distance;
		if (copyY)
			y = strumY + offsetY + 0 + Math.sin(angleDir) * distance;

		downscroll = strum.downScroll;
		if (wasGoodHit)
			setPosition(strumX + offsetX, strumY + offsetY);
	}

	public var glowing = false;
	public var tooLate:Bool = false;

	function set_noteType(value:String):String {
		colorSwap.hue = ClientPrefs.save.arrowHSV[data % 4][0] / 360;
		colorSwap.saturation = ClientPrefs.save.arrowHSV[data % 4][1] / 100;
		colorSwap.brightness = ClientPrefs.save.arrowHSV[data % 4][2] / 100;

		noteSplashHue = colorSwap.hue;
		noteSplashSat = colorSwap.saturation;
		noteSplashBrt = colorSwap.brightness;

		switch (value) {
			case 'hurt':
				ignoreNote = mustHit;
				texture = "rednotes";

				colorSwap.hue = 50;
				colorSwap.saturation = 20;
				colorSwap.brightness = 10;

				hitCausesMiss = true;

				return value;
		}

		return value;
	}
}

class ColorSwap {
	public var shader(default, null):ColorSwapShader = new ColorSwapShader();
	public var hue(default, set):Float = 0;
	public var saturation(default, set):Float = 0;
	public var brightness(default, set):Float = 0;

	private function set_hue(value:Float) {
		hue = value;
		shader.uTime.value[0] = hue;
		return hue;
	}

	private function set_saturation(value:Float) {
		saturation = value;
		shader.uTime.value[1] = saturation;
		return saturation;
	}

	private function set_brightness(value:Float) {
		brightness = value;
		shader.uTime.value[2] = brightness;
		return brightness;
	}

	public function new() {
		shader.uTime.value = [0, 0, 0];
		shader.awesomeOutline.value = [false];
	}
}

class ColorSwapShader extends FlxShader {
	@:glFragmentSource('
		varying float openfl_Alphav;
		varying vec4 openfl_ColorMultiplierv;
		varying vec4 openfl_ColorOffsetv;
		varying vec2 openfl_TextureCoordv;

		uniform bool openfl_HasColorTransform;
		uniform vec2 openfl_TextureSize;
		uniform sampler2D bitmap;

		uniform bool hasTransform;
		uniform bool hasColorTransform;

		vec4 flixel_texture2D(sampler2D bitmap, vec2 coord)
		{
			vec4 color = texture2D(bitmap, coord);
			if (!hasTransform)
			{
				return color;
			}

			if (color.a == 0.0)
			{
				return vec4(0.0, 0.0, 0.0, 0.0);
			}

			if (!hasColorTransform)
			{
				return color * openfl_Alphav;
			}

			color = vec4(color.rgb / color.a, color.a);

			mat4 colorMultiplier = mat4(0);
			colorMultiplier[0][0] = openfl_ColorMultiplierv.x;
			colorMultiplier[1][1] = openfl_ColorMultiplierv.y;
			colorMultiplier[2][2] = openfl_ColorMultiplierv.z;
			colorMultiplier[3][3] = openfl_ColorMultiplierv.w;

			color = clamp(openfl_ColorOffsetv + (color * colorMultiplier), 0.0, 1.0);

			if (color.a > 0.0)
			{
				return vec4(color.rgb * color.a * openfl_Alphav, color.a * openfl_Alphav);
			}
			return vec4(0.0, 0.0, 0.0, 0.0);
		}

		uniform vec3 uTime;
		uniform bool awesomeOutline;

		const float offset = 1.0 / 128.0;
		vec3 normalizeColor(vec3 color)
		{
			return vec3(
				color[0] / 255.0,
				color[1] / 255.0,
				color[2] / 255.0
			);
		}

		vec3 rgb2hsv(vec3 c)
		{
			vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
			vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
			vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

			float d = q.x - min(q.w, q.y);
			float e = 1.0e-10;
			return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
		}

		vec3 hsv2rgb(vec3 c)
		{
			vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
			vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
			return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
		}

		void main()
		{
			vec4 color = flixel_texture2D(bitmap, openfl_TextureCoordv);

			vec4 swagColor = vec4(rgb2hsv(vec3(color[0], color[1], color[2])), color[3]);

			// [0] is the hue???
			swagColor[0] = swagColor[0] + uTime[0];
			swagColor[1] = swagColor[1] + uTime[1];
			swagColor[2] = swagColor[2] * (1.0 + uTime[2]);
			
			if(swagColor[1] < 0.0)
			{
				swagColor[1] = 0.0;
			}
			else if(swagColor[1] > 1.0)
			{
				swagColor[1] = 1.0;
			}

			color = vec4(hsv2rgb(vec3(swagColor[0], swagColor[1], swagColor[2])), swagColor[3]);

			if (awesomeOutline)
			{
				 // Outline bullshit?
				vec2 size = vec2(3, 3);

				if (color.a <= 0.5) {
					float w = size.x / openfl_TextureSize.x;
					float h = size.y / openfl_TextureSize.y;
					
					if (flixel_texture2D(bitmap, vec2(openfl_TextureCoordv.x + w, openfl_TextureCoordv.y)).a != 0.
					|| flixel_texture2D(bitmap, vec2(openfl_TextureCoordv.x - w, openfl_TextureCoordv.y)).a != 0.
					|| flixel_texture2D(bitmap, vec2(openfl_TextureCoordv.x, openfl_TextureCoordv.y + h)).a != 0.
					|| flixel_texture2D(bitmap, vec2(openfl_TextureCoordv.x, openfl_TextureCoordv.y - h)).a != 0.)
						color = vec4(1.0, 1.0, 1.0, 1.0);
				}
			}
			gl_FragColor = color;

			/* 
			if (color.a > 0.5)
				gl_FragColor = color;
			else
			{
				float a = flixel_texture2D(bitmap, vec2(openfl_TextureCoordv + offset, openfl_TextureCoordv.y)).a +
						  flixel_texture2D(bitmap, vec2(openfl_TextureCoordv, openfl_TextureCoordv.y - offset)).a +
						  flixel_texture2D(bitmap, vec2(openfl_TextureCoordv - offset, openfl_TextureCoordv.y)).a +
						  flixel_texture2D(bitmap, vec2(openfl_TextureCoordv, openfl_TextureCoordv.y + offset)).a;
				if (color.a < 1.0 && a > 0.0)
					gl_FragColor = vec4(0.0, 0.0, 0.0, 0.8);
				else
					gl_FragColor = color;
			} */
		}')
	@:glVertexSource('
		attribute float openfl_Alpha;
		attribute vec4 openfl_ColorMultiplier;
		attribute vec4 openfl_ColorOffset;
		attribute vec4 openfl_Position;
		attribute vec2 openfl_TextureCoord;

		varying float openfl_Alphav;
		varying vec4 openfl_ColorMultiplierv;
		varying vec4 openfl_ColorOffsetv;
		varying vec2 openfl_TextureCoordv;

		uniform mat4 openfl_Matrix;
		uniform bool openfl_HasColorTransform;
		uniform vec2 openfl_TextureSize;

		attribute float alpha;
		attribute vec4 colorMultiplier;
		attribute vec4 colorOffset;
		uniform bool hasColorTransform;
		
		void main(void)
		{
			openfl_Alphav = openfl_Alpha;
			openfl_TextureCoordv = openfl_TextureCoord;

			if (openfl_HasColorTransform) {
				openfl_ColorMultiplierv = openfl_ColorMultiplier;
				openfl_ColorOffsetv = openfl_ColorOffset / 255.0;
			}

			gl_Position = openfl_Matrix * openfl_Position;

			openfl_Alphav = openfl_Alpha * alpha;
			if (hasColorTransform)
			{
				openfl_ColorOffsetv = colorOffset / 255.0;
				openfl_ColorMultiplierv = colorMultiplier;
			}
		}')
	public function new() {
		super();
	}
}
