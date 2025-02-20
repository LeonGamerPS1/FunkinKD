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
		#if hl
		hl.Gc.major();
		#elseif cpp
		cpp.vm.Gc.run(true);
		#end
	}
}
