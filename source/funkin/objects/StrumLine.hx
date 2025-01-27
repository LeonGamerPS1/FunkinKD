package funkin.objects;

class StrumLine extends FlxTypedSpriteGroup<StrumNote>
{
	public function new(downScroll:Bool, ?player:Bool = false)
	{
		var targetX:Float = 50;
		if (player)
			targetX += FlxG.width / 2 + (Note.swagWidth / 2);

		super(targetX, downScroll ? FlxG.height - 150 : 50);

		for (i in 0...4)
		{
			var strumNote:StrumNote = new StrumNote(i);
			strumNote.downScroll = downScroll;
			strumNote.x += (160 * 0.7) * i;
			add(strumNote);
		}
	}
}
