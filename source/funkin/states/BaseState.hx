package funkin.states;

import flixel.addons.ui.FlxUIState;
import funkin.controls.Action.Controls;

class BaseState extends FlxUIState
{
	var controls:Controls;

	public function new()
	{
		super();
		controls = new Controls("FUNKIN_CONTROLS");
		FlxG.inputs.add(controls);
	}
}
