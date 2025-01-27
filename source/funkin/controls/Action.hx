package funkin.controls;

import flixel.addons.input.FlxControls;
import flixel.addons.input.FlxControlInputType;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepadInputID;

enum Action
{
	
	@:inputs([FlxKey.UP, FlxKey.W, DPAD_UP, LEFT_STICK_DIGITAL_UP, FlxVirtualPadInputID.UP])
	NOTE_UP;


	@:inputs([FlxKey.DOWN, FlxKey.S, DPAD_DOWN, LEFT_STICK_DIGITAL_DOWN, FlxVirtualPadInputID.DOWN])
	NOTE_DOWN;


	@:inputs([FlxKey.LEFT, FlxKey.A, DPAD_LEFT, LEFT_STICK_DIGITAL_LEFT, FlxVirtualPadInputID.LEFT])
	NOTE_LEFT;


	@:inputs([FlxKey.RIGHT, FlxKey.D, DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT, FlxVirtualPadInputID.RIGHT])
	NOTE_RIGHT;
}

class Controls extends FlxControls<Action> {}