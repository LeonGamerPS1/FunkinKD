package funkin.objects;

class ChartSustain extends Sustain {
	public function new(parent:Note, gridBG:FlxSprite, daSus:Float = 0) {
		super(parent);

		setGraphicSize(parent.width / 3);
		updateHitbox();
		height = FlxMath.remapToRange(daSus, 0, parent.conductor.stepLength * 16, 0, gridBG.height);
	}
}
