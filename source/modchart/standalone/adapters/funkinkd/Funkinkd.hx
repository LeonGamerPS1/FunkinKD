package modchart.standalone.adapters.funkinkd;

import modchart.standalone.IAdapter;

class Funkinkd implements IAdapter
{
	private var __receptorXs:Array<Array<Float>> = [];
	private var __receptorYs:Array<Array<Float>> = [];

	public function onModchartingInitialization()
	{
		@:privateAccess
		PlayState.instance.playField.strumLineNotes.forEachAlive(strumNote ->
		{
			if (__receptorXs[strumNote.player] == null)
				__receptorXs[strumNote.player] = [];
			if (__receptorYs[strumNote.player] == null)
				__receptorYs[strumNote.player] = [];

			__receptorXs[strumNote.player][strumNote.data] = strumNote.x;
			__receptorYs[strumNote.player][strumNote.data] = getDownscroll() ? FlxG.height - strumNote.y - Manager.ARROW_SIZE : strumNote.y;
		});
	}

	public function getBeatFromStep(step:Float)
		return step * .25;

	public function getHoldParentTime(arrow:FlxSprite)
	{
		final note:Note = cast arrow;
		return note.time;
	}

	// Song-related stuff
	public function getSongPosition():Float // Current song position
	{
		var songPos:Float = 0;
		if (PlayState.instance != null)
			songPos = PlayState.instance.playField.conductor.songPosition;
		return songPos;
	}

	// public function getCrochet():Float           // Current beat crochet
	public function getStaticCrochet():Float // Beat crochet without bpm changes
	{
		var crochet:Float = 0;
		if (PlayState.instance != null)
			crochet = PlayState.instance.playField.conductor.beatLength;
		return crochet;
	}

	public function getCurrentBeat():Float // Current beat
	{
		var beat:Float = 0;
		if (PlayState.SONG != null)
			beat = (getSongPosition() / 1000)*(PlayState.instance.playField.conductor.bpm/60);
		return beat;
	}

	public function getCurrentScrollSpeed():Float // Current arrow scroll speed
	{
		var speed:Float = 0;
		if (PlayState.SONG != null)
			speed = PlayState.SONG.speed;
		return speed;
	}

	// Arrow-related stuff
	public function getDefaultReceptorX(lane:Int, player:Int):Float
	{
		return __receptorXs[player][lane];
	}

	public function getDefaultReceptorY(lane:Int, player:Int):Float
	{
		return __receptorYs[player][lane];
	}

	public function getTimeFromArrow(arrow:FlxSprite):Float // Get strum time for arrow
	{
		if (arrow is Note)
			return cast(arrow, Note).time;
		return 0.0;
	}

	public function isTapNote(sprite:FlxSprite):Bool // If the sprite is an arrow, return true, if it is an receptor/strum, return false
	{
		if (sprite is Note)
			return true;
		else
			return false;
	}

	public function isHoldEnd(sprite:FlxSprite):Bool // If its the hold end
	{
		if (sprite is Note)
			cast(sprite, Note).animation.curAnim.name == "end";
		return false;
	}

	public function arrowHit(sprite:FlxSprite):Bool // If the arrow was hitted
	{
		if (sprite is Note)
			return cast(sprite, Note).wasGoodHit || cast(sprite, Note).wasHit;

		return false;
	}

	public function getLaneFromArrow(sprite:FlxSprite):Int // Get lane/note data from arrow
	{
		var data:Int = 0;
		if (sprite is StrumNote)
			data = cast(sprite, StrumNote).data;
		if (sprite is Note)
			data = cast(sprite, Note).data;
		return data;
	}

	public function getPlayerFromArrow(sprite:FlxSprite):Int // Get player from arrow
	{
		var player:Int = 0;

		if (sprite is Note)
			player = (cast(sprite, Note).mustHit ? 1 : 0);

		if (sprite is StrumNote)
			player = (cast(sprite, StrumNote).mustHit ? 1 : 0);
		return player;
	}

	public function getKeyCount(?player:Int):Int // Get total key count (4 for almost every engine)
		return 4;

	public function getPlayerCount():Int // Get total player count (2 for almost every engine)
		return 2;

	// Get cameras to render the arrows (camHUD for almost every engine)
	public function getArrowCamera():Array<FlxCamera>
		return [PlayState.instance.camHUD];

	// Options section
	public function getHoldSubdivisions():Int // Hold resolution
		return 1;

	public function getDownscroll():Bool // Get if it is downscroll
		return ClientPrefs.save.downScroll;

	/**
	 * Get the every arrow/receptor indexed by player.
	 * 0 receptors,
	 * 1 tap arrows,
	 * 2 sustains
	 * @return Array<Array<Array<FlxSprite>>>
	 */
	public function getArrowItems():Array<Array<Array<FlxSprite>>>
	{
		var array:Array<Array<Array<FlxSprite>>> = [[[], [], []], /** left is cpu strums**/ [[], [], []]];
		PlayState.instance.playField.oppStrums.forEachAlive(function(e)
		{
			array[0][0].push(e);
		});

		PlayState.instance.playField.playerStrums.forEachAlive(function(e)
		{
			array[1][0].push(e);
		});

		PlayState.instance.playField.notes.forEachAlive(function(e)
		{
			if (e.isSustainNote)
			{
				if (e.mustHit)
					array[1][2].push(e);
				else
					array[0][2].push(e);
				return;
			}
			else
			{
				if (e.mustHit)
					array[1][1].push(e);
				else
					array[0][1].push(e);
			}
		});

		return array;
	}
}
