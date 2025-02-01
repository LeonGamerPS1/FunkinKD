package funkin.objects;

class StrumLine extends FlxTypedSpriteGroup<StrumNote>
{
	public var player:Bool = false;

	public function new(downScroll:Bool, ?player:Bool = false)
	{
		var targetX:Float = Note.swagWidth * 1.5;
		if (player)
			targetX =  50 + (FlxG.width / 2 + (Note.swagWidth / 2));

		super(targetX, downScroll ? FlxG.height - 150 : 50);
		this.player = player;
		for (i in 0...4)
		{
			var strumNote:StrumNote = new StrumNote(i,PlayState.isPixelStage);
			strumNote.downScroll = downScroll;
			strumNote.x += (160 * 0.7) * i;
			add(strumNote);
		}
	}
}
