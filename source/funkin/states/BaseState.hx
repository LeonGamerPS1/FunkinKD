package funkin.states;

import funkin.controls.Action.Controls;

class BaseState extends FlxState {
    var controls:Controls;
    public function new() {
        super();
        controls = new Controls("FUNKIN_CONTROLS");
        FlxG.inputs.addUniqueType(controls);
    }
}