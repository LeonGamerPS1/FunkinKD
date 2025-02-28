package funkin.objects;

class StrumLine extends FlxTypedSpriteGroup<StrumNote> {
	public var player:Bool = false;

	public function new(downScroll:Bool = false, ?player:Bool = false) {
		var targetX:Float = 50 + (Note.swagWidth / 4);
		if (player)
			targetX = 50 + (FlxG.width / 2) + (Note.swagWidth / 2);

		super(targetX, downScroll ? FlxG.height - 150 : 50);
		this.player = player;

		for (i in 0...4) {
			var strumNote:StrumNote = new StrumNote(i, PlayState.isPixelStage);
			strumNote.downScroll = downScroll;
			strumNote.x += Note.swagWidth * i;
			strumNote.defaultX = strumNote.x + targetX;
			strumNote.player = player ? 1 : 0;
			strumNote.defaultY = strumNote.y + y;
			strumNote.mustHit = player;
			add(strumNote);
		}
	}
}
