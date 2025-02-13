package funkin.objects.gameplay.stages;

class GlitchSchool extends BaseStage
{
	override function create()
	{
		super.create();
		var bg:BGSprite;
		var posX = -900;
		var posY = -1000;

		bg = new BGSprite('weebschoolglitch', posX, posY, 0.9, 0.9, ['background 2 instance 1'], true);
		bg.setGraphicSize(bg.width * 6, bg.height * 6);
		bg.updateHitbox();
		add(bg);
	}
}
