package funkin.objects;

class StrumLine extends FlxTypedSpriteGroup<StrumNote>
{
	public var player:Bool = false;

	public function new(downScroll:Bool, ?player:Bool = false)
	{
		var targetX:Float = 50 + (Note.swagWidth / 4);
		if (player)
			targetX =  50 + (FlxG.width / 2) + (Note.swagWidth / 2);

		super(targetX, downScroll ? FlxG.height - 150 : 50);
		this.player = player;

		
		for (i in 0...4)
		{
			var strumNote:StrumNote = new StrumNote(i,PlayState.isPixelStage);
			strumNote.downScroll = downScroll;
			strumNote.x += (160 * 0.7) * i;
			strumNote.defaultX = strumNote.x;
			strumNote.player = player ? 1 : 0;
			strumNote.defaultY = strumNote.y;
			strumNote.mustHit = player;
			add(strumNote);
		}
	}
}
