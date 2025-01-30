package funkin.states;

import flixel.text.FlxText;

class OhNoState extends BaseState
{
	public var errorMessage:String;
	public var text:FlxText;

	public function new(errorMessage:String = "Oh no!")
	{
		super();
		this.errorMessage = errorMessage;
	}

	override function create()
	{
		super.create();
		text = new FlxText(0, FlxG.height / 2, FlxG.width, errorMessage, 24);
		add(text);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (controls.justPressed.UI_BACK)
			FlxG.switchState(new MainMenu());
	}
}
