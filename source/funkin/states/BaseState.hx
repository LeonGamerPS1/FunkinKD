package funkin.states;

import haxe.ui.backend.flixel.UIState;
import flixel.addons.ui.FlxUIState;
import funkin.controls.Action.Controls;

class BaseState extends UIState
{
	var controls:Controls;

	public function new()
	{
		super();
		controls = new Controls("FUNKIN_CONTROLS");
		FlxG.inputs.addUniqueType(controls);
	}
}
