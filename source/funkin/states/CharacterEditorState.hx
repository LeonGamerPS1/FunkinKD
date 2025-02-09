package funkin.states;

import flixel.text.FlxText;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUIButton;
import flixel.util.typeLimit.OneOfTwo;
import funkin.objects.Character;
import flixel.group.FlxGroup;
import flixel.addons.ui.FlxUITabMenu;
import flixel.ui.FlxButton;

class CharacterEditorState extends BaseState {
	public var cross:FlxSprite;
	public var camHUD:FlxCamera;

	public var uiGroup:FlxGroup = new FlxGroup();

	public var camZoom:Float = 1;
	public var camFollow:FlxObject = new FlxObject(0, 0, 1, 1).screenCenter();

	public var character:Character;
	public var curCharacter:String = "dad";

	public var tabs:FlxUITabMenu;
	public var back:FlxSprite;
    public var infoText:FlxText;

	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;

	public function new(?curCharacter:String = "dad") {
		this.curCharacter = curCharacter;
		super();
	}

	override function create() {
		new School(this, true);

		character = new Character(curCharacter);
		character.setPosition(DAD_X, DAD_Y);
		add(character);

		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD, false);

		uiGroup = new FlxGroup();
		uiGroup.cameras = [camHUD];
		add(uiGroup);

		back = new FlxSprite(0, 0, Paths.image('editors/char/tab_bg'));
		back.x = FlxG.width;
		back.x -= back.width;
		back.screenCenter(Y);
		uiGroup.add(back);

		var tab = [{name: "Main Info", label: 'Main Info'}, {name: "Animation", label: 'Animation'}];

		tabs = new FlxUITabMenu(back, tab,);
	
		tabs.screenCenter(Y);
		tabs.y = back.y;
		tabs.x = back.x;
		tabs.scrollFactor.set(0, 0);
		tabs.cameras = [camHUD];
		back.x = tabs.x;
		uiGroup.add(tabs);

		addAnimationUI();
		addMainInfoUI();
		for (i in 0...tabs.length) {
			var butt:OneOfTwo<FlxButton,FlxSprite> = tabs.members[i];
			if (!(butt == back)) {
				cast(butt,FlxSprite).loadGraphic(Paths.image('editors/char/button'));
				cast(butt,FlxSprite).scrollFactor.set(0, 0);
				cast(butt,FlxSprite).cameras = [camHUD];
			}
	

			if(Std.isOfType(butt,FlxUIButton))
				cast(butt,FlxUIButton).label.color = FlxColor.WHITE;
		}

		cross = new FlxSprite(0, 0).loadGraphic(Paths.image("editors/char/cross"));
		cross.screenCenter();
		uiGroup.add(cross);

		FlxG.camera.follow(camFollow, LOCKON, 0.09);

	}

	function addAnimationUI():Void {
		var Animation = new FlxUI(null, tabs);
		Animation.name = 'Animation';

		tabs.addGroup(Animation);
	}

	function addMainInfoUI():Void {
		var info = new FlxUI(null, tabs);
		info.name = 'Main Info';

		var button:FlxButton = new FlxButton( 0, 20, "FlipX?", function() {
			swapPlayer(character.isPlayer,!character.json.flipX);
		}); 
		info.add(button);
		button.loadGraphic(Paths.image('editors/char/button'));

		var button:FlxButton = new FlxButton(button.x, button.y + 30, "is Playable Character?", function() {
			swapPlayer(!character.isPlayer,character.json.flipX);
		}); 
		button.loadGraphic(Paths.image('editors/char/button'));
		info.add(button);


		tabs.addGroup(info);
	}

	public function focusOnCharacter() {
		camFollow.setPosition(character.getMidpoint().x + 150, character.getMidpoint().y - 100);
		if (character.isPlayer) {
			camFollow.setPosition(character.getMidpoint().x - 150, character.getMidpoint().y - 100);
			camFollow.x -= character.camera_position[0];
			camFollow.y += character.camera_position[1];
			
		} else {
			camFollow.x += character.camera_position[0];
			camFollow.y += character.camera_position[1];
	
		}
	}

	public function swapPlayer(isPlayer:Bool = false, flipX:Bool = false) {

		character.isPlayer = isPlayer;
		character.json.flipX = flipX;
		character.flipX = (character.json.flipX != isPlayer);
		if(isPlayer)
			character.setPosition(BF_X, BF_Y);
		else
			character.setPosition(DAD_X, DAD_Y);
		focusOnCharacter();
	}

	override function update(elapsed:Float) {
		
		if (controls.pressed.UI_LEFT)
			camFollow.x -= 25;
		if (controls.pressed.UI_DOWN)
			camFollow.y += 25;
		if (controls.pressed.UI_RIGHT)
			camFollow.x += 25;
		if (controls.pressed.UI_UP)
			camFollow.y -= 25;
		if (controls.justPressed.UI_BACK) {
			FlxG.switchState(new PlayState());
		}
		if (controls.justPressed.UI_RESET) {
			camZoom = 0.9;
			focusOnCharacter();
		}
        if (controls.justPressed.UI_ACCEPT) {
			character.playAnim(character.getAnimationName(),true);
		}

		super.update(elapsed);
		FlxG.camera.zoom = FlxMath.lerp(camZoom, FlxG.camera.zoom, Math.exp(-elapsed * 8));
	}
}