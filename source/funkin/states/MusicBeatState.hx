package funkin.states;

class MusicBeatState extends BaseState
{
	public var stages:Array<BaseStage> = [];

	public function stagesFunc(?func:(stage:BaseStage) -> Void)
	{
		if (func == null)
			return;
		for (i in 0...stages.length)
		{
			var stage:BaseStage = stages[i];
			func(stage);
		}
	}

	public function addStage(stage:BaseStage)
	{
		if (!stages.contains(stage))
			stages.push(stage);
	}
}
