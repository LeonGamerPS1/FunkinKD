package funkin.objects.gameplay.stages;

class BaseStage extends FlxBasic {
	var parent:FlxState;
	var boyfriend(get, null):Character;
	var dad(get, null):Character;
	var gf(get, null):Character;
	public var curStep:Int = 0;
	public var curBeat:Int = 0;

	public function new(parentState:FlxState, autoCreate:Bool = false) {
		super();
		parent = parentState;
		if (parent is MusicBeatState)
			cast(parent, MusicBeatState).addStage(this);
		parent.add(this);

		if (autoCreate == true)
			create();
	}

	public function create() {}

	public function setStartCallback(fnc:() -> Void) {
		if (parent != null)
			if (parent is PlayState)
				cast(parent, PlayState).startCallback = fnc;
	}

	public function startCountdown() {
		if (parent != null)
			@:privateAccess
			if (parent is PlayState)
				cast(parent, PlayState).startCountdown();
	}

	public function createPost() {}

	public function add(basic:FlxBasic) {
		if (parent != null) {
			return parent.add(basic);
		}
		return null;
	}

	public function remove(basic:FlxBasic) {
		if (parent != null)
			parent.remove(basic);
	}

	public function updatePost(elapsed:Float) {}

	public function stepHit() {}

	public function beatHit() {}

	public function sectionHit() {}

	function get_boyfriend():Character {
		if (parent is PlayState)
			return cast(parent, PlayState).boyfriend;
		return null;
	}

	function get_gf():Character {
		if (parent is PlayState)
			return cast(parent, PlayState).girlfriend;
		return null;
	}

	function get_dad():Character {
		if (parent is PlayState)
			return cast(parent, PlayState).dad;
		return null;
	}
}
