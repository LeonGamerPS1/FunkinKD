package funkin.graphics.shaders;

import flixel.system.FlxAssets.FlxShader;

class UVBending extends FlxShader {
    @:glFragmentSource(" 
     // Automatically converted with https://github.com/TheLeerName/ShadertoyToFlixel

#pragma header

#define iResolution vec3(openfl_TextureSize, 0.)
uniform float iTime;
#define iChannel0 bitmap
#define texture flixel_texture2D

// end of ShadertoyToFlixel header

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    vec2 x_range = vec2(-1,1);
    
    uv.x = mix(x_range.x, x_range.y, uv.x);
    uv.y -= cos(uv.x) * cos(iTime);
    
    vec3 col = texture(iChannel0, uv).rrr;

    fragColor = vec4(col, texture(iChannel0, uv).a);
}

void main() {
	mainImage(gl_FragColor, openfl_TextureCoordv*openfl_TextureSize);
}
    ")
	public function new() {
		super();
	}
}
