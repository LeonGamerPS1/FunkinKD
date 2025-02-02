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

	@:inputs([FlxKey.LEFT, FlxKey.A, DPAD_LEFT, LEFT_STICK_DIGITAL_LEFT, FlxVirtualPadInputID.LEFT])
	UI_LEFT;

	@:inputs([FlxKey.DOWN, FlxKey.S, DPAD_DOWN, LEFT_STICK_DIGITAL_DOWN, FlxVirtualPadInputID.DOWN])
	UI_DOWN;

	@:inputs([FlxKey.UP, FlxKey.W, DPAD_UP, LEFT_STICK_DIGITAL_UP, FlxVirtualPadInputID.UP])
	UI_UP;

	@:inputs([FlxKey.RIGHT, FlxKey.D, DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT, FlxVirtualPadInputID.RIGHT])
	UI_RIGHT;

	@:inputs([FlxKey.BACKSPACE, FlxKey.ESCAPE,B, BACK])
	UI_BACK;

	@:inputs([FlxKey.ENTER, FlxKey.SPACE,A, FlxVirtualPadInputID.A])
	UI_ACCEPT;

	@:inputs([FlxKey.R, X])
	UI_RESET;

}

class Controls extends FlxControls<Action> {}