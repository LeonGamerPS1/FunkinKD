package funkin.objects;

import flixel.system.FlxAssets;
import funkin.backend.recycling.data.ChartNote;

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

	public static var swagWidth:Float = (160 / 2) * 0.7;

	public var wasMissed:Bool = false;
	public var multSpeed:Float = 1;

	public function canBeHit(conductor:Conductor):Bool {
		if (mustHit
			&& time > conductor.songPosition - (Conductor.safeZoneOffset)
			&& time < conductor.songPosition + (Conductor.safeZoneOffset * 0.5))
			return true;
		else
			return false;
	}

	public function new(time:Float = 0, data:Int = 0, ?isPixel:Bool = false, ?prevNote:Note, ?sustainSpeed:Float = 1, ?conductor:Conductor, sus:Bool = false) {
		super(0, -2000);

		this.data = data;
		this.isPixel = isPixel;
		this.time = time;
		this.prevNote = prevNote;
		this.conductor = conductor;
		isSustainNote = sus;
		texture = "notes";

		reloadNote(texture, isPixel, sustainSpeed);
		if (!isSustainNote)
			playAnim("arrow");
		else
			multAlpha = 0.7;
	}

	public function playAnim(s:String, force:Bool = false) {
		animation.play(s, force);
		centerOffsets();
		centerOrigin();
	}

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
			if (!wasGoodHit && time <= conductor.songPosition)
				if (!isSustainNote || (prevNote.wasGoodHit && !ignoreNote))
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
				prevNote.scale.y = 6 * (conductor.stepLength / 100 * 1.254 * sustainSpeed);
				prevNote.updateHitbox();
			}
		}
	}

	function loadDefaultNoteAnims(tex:String, ?sustainSpeed:Float = 1) {
		frames = Paths.getSparrowAtlas('noteSkins/$tex');

		animation.addByPrefix('arrow', '${directions[data % directions.length]}0', 24, false);
		animation.addByPrefix('hold', '${directions[data % directions.length]} hold piece', 24, false);
		animation.addByPrefix('end', '${directions[data % directions.length]} hold end', 24, false);

		setGraphicSize(width * 0.7);
		updateHitbox();

		if (isSustainNote && prevNote != null) {
			playAnim('end');
			updateHitbox();
			if (prevNote != null && prevNote.isSustainNote) {
				prevNote.playAnim('hold');
				prevNote.scale.y = 0.7 * (conductor.stepLength / 100 * 1.5 * sustainSpeed);
				prevNote.updateHitbox();
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

	public var copyX:Null<Bool> = true;
	public var copyY:Null<Bool> = true;
	public var copyAngle:Null<Bool> = true;
	public var copyAlpha:Null<Bool> = true;
	public var isSustainNote:Bool = false;

	public function followStrumNote(myStrum:StrumNote, conductor:Conductor, ?songSpeed:Float = 1) {
		this.strum = myStrum;

		songSpeed = FlxMath.roundDecimal(songSpeed, 2);

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
		angle = strumDirection - 90 + strumAngle;

		if (copyX)
			x = strumX + offsetX + Math.cos(angleDir) * distance;
		if (isSustainNote)
			x = strumX + (strum.width / 2) - (width / 2) + Math.cos(angleDir) * distance;
		if (copyY)
			y = strumY + offsetY + 0 + Math.sin(angleDir) * distance;

		downscroll = strum.downScroll;
	}

	var glowing = false;

	override function set_clipRect(rect:FlxRect):FlxRect {
		clipRect = rect;
		if (frames != null)
			frame = frames.frames[animation.frameIndex];
		return clipRect = rect;
	}

	public function clipToStrumNote(myStrum:StrumNote) {
		var center:Float = myStrum.y + myStrum.height * 0.5;

		if ((mustHit || !mustHit)
			&& (wasGoodHit
				|| ((prevNote.wasGoodHit || (prevNote.prevNote != null && prevNote.prevNote.wasGoodHit)) && !canBeHit(conductor)))) {
			var swagRect:FlxRect;

			swagRect = FlxRect.get(0, 0, frameWidth, frameHeight);

			if (myStrum.downScroll) {
				if (y - offset.y * scale.y + height >= center) {
					swagRect.width = frameWidth;
					swagRect.height = Std.int((center - y) / scale.y);
					swagRect.y = Std.int(frameHeight - swagRect.height);
				}
			} else if (y + offset.y * scale.y <= center) {
				swagRect.y = (center - y) / scale.y;
				swagRect.width = width / scale.x;
				swagRect.height = (height / scale.y) - swagRect.y;
			}

			clipRect = swagRect;
			swagRect.put();
		}
	}
}

class BrightnessShader extends FlxShader {
	@:glFragmentSource("
	// Automatically converted with https://github.com/TheLeerName/ShadertoyToFlixel

#pragma header

#define iResolution vec3(openfl_TextureSize, 0.)
#define iChannel0 bitmap
#define texture flixel_texture2D

// end of ShadertoyToFlixel header

mat4 brightnessMatrix( float brightness )
{
    return mat4( 1, 0, 0, 0,
                 0, 1, 0, 0,
                 0, 0, 1, 0,
                 brightness, brightness, brightness, 1 );
}

mat4 contrastMatrix( float contrast )
{
	float t = ( 1.0 - contrast ) / 2.0;
    
    return mat4( contrast, 0, 0, 0,
                 0, contrast, 0, 0,
                 0, 0, contrast, 0,
                 t, t, t, 1 );

}

mat4 saturationMatrix( float saturation )
{
    vec3 luminance = vec3( 0.3086, 0.6094, 0.0820 );
    
    float oneMinusSat = 1.0 - saturation;
    
    vec3 red = vec3( luminance.x * oneMinusSat );
    red+= vec3( saturation, 0, 0 );
    
    vec3 green = vec3( luminance.y * oneMinusSat );
    green += vec3( 0, saturation, 0 );
    
    vec3 blue = vec3( luminance.z * oneMinusSat );
    blue += vec3( 0, 0, saturation );
    
    return mat4( red,     0,
                 green,   0,
                 blue,    0,
                 0, 0, 0, 1 );
}

const float brightness = 0.15;
const float contrast = 1.2;
const float saturation = 1.5;

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec4 color = texture( iChannel0, fragCoord/iResolution.xy );
    
	fragColor = brightnessMatrix( brightness ) *
        		contrastMatrix( contrast ) * 
        		saturationMatrix( saturation ) *
        		color;
}

void main() {
	mainImage(gl_FragColor, openfl_TextureCoordv*openfl_TextureSize);
}
	")
}
