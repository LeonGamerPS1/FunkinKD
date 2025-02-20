package funkin.states;

import flixel.addons.display.FlxGridOverlay;
import flixel.addons.display.FlxBackdrop;

class ChartingState extends BaseState
{
	var song:SongData;
	var COLOR1:FlxColor = FlxColor.fromRGB(55, 55, 55);
	var COLOR2:FlxColor = FlxColor.WHITE;

	var CELL_SIZE:Int = 60;
	var GRID_SCROLL_SPEED:Float = 1.2;
	var bg:FlxBackdrop;

	override function create()
	{
		super.create();

		if (PlayState.SONG != null)
			song = PlayState.SONG;
		else
			song = {
				song: "Tutorial",
				bpm: 100.0,
				sections: [],
				speed: 1.0,
				player1: "bf",
				player2: "gf",
				gfVersion: "gf",

				stage: "stage",
				skin: ""
			};

		bg = new FlxBackdrop(FlxGridOverlay.createGrid(CELL_SIZE, CELL_SIZE, FlxG.width, FlxG.height, true, COLOR1, COLOR2));
        
		add(bg);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		bg.setPosition(bg.x + GRID_SCROLL_SPEED, bg.y + GRID_SCROLL_SPEED);
	}
}
