package funkin.states;

import flixel.addons.ui.FlxUICheckBox;

class OptionsState extends BaseState {
	override function create() {
		super.create();

		var downScrollBox:FlxUICheckBox;

		downScrollBox = new FlxUICheckBox(0, 0, null, null, "downScroll", 100, null);
		downScrollBox.checked = ClientPrefs.save.downScroll;
		downScrollBox.callback = function() {
			ClientPrefs.save.downScroll = Reflect.getProperty(downScrollBox, "checked");
		};

		add(downScrollBox);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		if (controls.justPressed.UI_BACK)
			FlxG.switchState(new MainMenu());
	}
}
