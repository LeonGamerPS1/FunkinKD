package funkin.objects;

import flixel.system.FlxAssets;
import funkin.backend.recycling.data.ChartNote;

class Note extends FlxSprite
{
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

	public function canBeHit(conductor:Conductor):Bool
	{
		if (mustHit
			&& time > conductor.songPosition - (Conductor.safeZoneOffset)
			&& time < conductor.songPosition + (Conductor.safeZoneOffset * 0.5))
			return true;
		else
			return false;
	}

	public function new(time:Float = 0, data:Int = 0, ?isPixel:Bool = false, ?prevNote:Note, ?sustainSpeed:Float = 1, ?conductor:Conductor)
	{
		super(0, -20000);

		this.data = data;
		this.isPixel = isPixel;
		this.time = time;
		this.prevNote = prevNote;
		this.conductor = conductor;
		texture = "notes";

		reloadNote(texture, isPixel, sustainSpeed);
		playAnim("arrow");
	}

	public function playAnim(s:String, force:Bool = false)
	{
		animation.play(s, force);
		centerOffsets();
		centerOrigin();
	}

	function reloadNote(tex:String = "notes", isPixel:Bool, ?sustainSpeed:Float = 1)
	{
		tex ??= "notes";
		if (PlayState.SONG.skin != null && PlayState.SONG.skin != "")
			tex = PlayState.SONG.skin;
		this.isPixel = isPixel;
		var prefix = isPixel ? "pixel/" : "";
		var path = Paths.image('noteSkins/$prefix$tex');
		if (!Assets.exists(path))
		{
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

	override function update(elapsed:Float)
	{
		if (!mustHit)
			if (!wasGoodHit && time <= conductor.songPosition)
				wasGoodHit = true;

		super.update(elapsed);
	}

	function loadPixelNoteAnimations(tex:String, ?sustainSpeed:Float = 1)
	{
		pixelPerfectPosition = true;
		pixelPerfectRender = true;

		loadGraphic(Paths.image('noteSkins/pixel/$tex'), true, 17, 17);

		animation.add('arrow', [data % 4 + 4], 12, false);
		setGraphicSize(width * 6);

		antialiasing = false;
		updateHitbox();
	}

	function loadDefaultNoteAnims(tex:String, ?sustainSpeed:Float = 1)
	{
		frames = Paths.getSparrowAtlas('noteSkins/$tex');

		animation.addByPrefix('arrow', '${directions[data % directions.length]}0', 24, false);
		animation.addByPrefix('hold', '${directions[data % directions.length]} hold piece', 24, false);
		animation.addByPrefix('end', '${directions[data % directions.length]} hold end', 24, false);

		setGraphicSize(width * 0.7);
		updateHitbox();

		antialiasing = true;
		if (sustain != null)
			sustain.antialiasing = antialiasing;
	}

	function set_texture(value:String):String
	{
		texture = value;

		reloadNote(value, isPixel);
		return texture = value;
	}

	public var offsetY:Float = 0;
	public var multAlpha:Float = 1;
	public var sustain:Sustain;

	public function followStrumNote(strum:StrumNote, conductor:Conductor, ?songSpeed:Float = 1)
	{
		this.strum = strum;
		songSpeed = FlxMath.roundDecimal(songSpeed, 2);

		if (x != strum.x + offsetX)
			x = strum.x + offsetX;

		alpha = strum.alpha * multAlpha;
		y = strum.y + (time - conductor.songPosition) * 0.45 * (songSpeed * (!strum.downScroll ? 1 : -1)) + offsetY;

		downscroll = strum.downScroll;
	}

	public function setup(chartNote:funkin.backend.recycling.data.ChartNote):Note
	{
		wasGoodHit = false;
		wasHit = false;
		wasMissed = false;
		length = chartNote.length;
		data = chartNote.data;
		mustHit = chartNote.mustHit;
		time = chartNote.time;
		isPixel = chartNote.pixel;
		scrollSpeed = chartNote.speed;

		reloadNote(texture, isPixel, chartNote.speed);
		playAnim("arrow");
		revive();

		return this;
	}

	var glowing = false;

	override function draw()
	{
		if (!wasHit || !wasGoodHit)
			super.draw();
	}

	override function destroy()
	{
		if (sustain != null)
			sustain.destroy();

		super.destroy();
	}
}

class BrightnessShader extends FlxShader
{
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
