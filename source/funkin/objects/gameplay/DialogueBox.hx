package funkin.objects.gameplay;

import flixel.addons.text.FlxTypeText;
import haxe.Constraints.Function;

class DialogueBox extends FlxTypedSpriteGroup<FlxSprite> {
	var curLine:Int = -1;
	var port:FlxSprite;
	var finishCB:Function;
	var dialogueJSON:DialogueFile;
	var box:FlxSprite;
	var text:FlxTypeText;
	var sound:FlxSound;

	public function new(dialogueJSON:DialogueFile, finishCB:Function) {
		super();
		this.finishCB = finishCB;
		this.dialogueJSON = dialogueJSON;

		alpha = 0;
		FlxTween.tween(this, {alpha: 1}, 0.5);

		sound = new FlxSound();
		sound.loadEmbedded(Paths.music('Lunchbox'), true);
		sound.play();
		FlxG.sound.list.add(sound);

		bgFade = new FlxSprite(-200, -200).makeGraphic(Std.int(FlxG.width * 1.3), Std.int(FlxG.height * 1.3), 0xFFB3DFd8);
		bgFade.scrollFactor.set();
		bgFade.alpha = 0;
		add(bgFade);

		new FlxTimer().start(0.83, function(tmr:FlxTimer) {
			bgFade.alpha += (1 / 5) * 0.7;
			if (bgFade.alpha > 0.7)
				bgFade.alpha = 0.7;
		}, 5);

		port = new FlxSprite();
		box = new FlxSprite(-20, 45);

		box.frames = Paths.getSparrowAtlas('weeb/pixelUI/dialogueBox-pixel');
		box.animation.addByPrefix('normalOpen', 'Text Box Appear', 24, false);
		box.animation.addByIndices('normal', 'Text Box Appear instance 1', [4], '', 24);

		box.animation.play('normalOpen');
		box.setGraphicSize(Std.int(box.width * PlayState.daPixelZoom * 0.9));
		box.updateHitbox();
		add(box);

		box.screenCenter(X);
		text = new FlxTypeText(240, 500, Std.int(FlxG.width * 0.6), '', 32);
		text.setFormat(Paths.fontotf("pixel"), 30, FlxColor.BROWN, null, OUTLINE, 0x6E2001);
		text.borderSize = 4;

		text.sounds = [new FlxSound().loadEmbedded(Paths.sound("pixelText"))];
		text.start(0.03, true);
		add(text);

		nextDialog();
	}

	function nextDialog():Void {
		curLine++;

		if (curLine > dialogueJSON.dialogue.length - 1) {
			FlxTween.tween(this, {alpha: 0}, 1, {onComplete: end});

			return;
		}

		var lastDialogue:DialogueLine = dialogueJSON.dialogue[curLine];
		text.resetText(lastDialogue.text);
		text.color = 0x4E1010;
		text.start(0.03, true);

		dialogueChars(lastDialogue.portrait, lastDialogue.isDad);
	}

	var lastDad = false;
	function dialogueChars(char:String, isDad:Bool = false) {
	
		if (isDad) {
			if (portraitDad == null)
				portraitDad = new FlxSprite(-20, 40);

			portraitDad.frames = Paths.getAtlas('dialogue/$char');
			portraitDad.animation.addByPrefix('enter', 'slidein', 24, false);
			portraitDad.setGraphicSize(Std.int(portraitDad.width * PlayState.daPixelZoom * 0.9));
			portraitDad.updateHitbox();
			portraitDad.scrollFactor.set();

			if (lastDad != isDad)
				portraitDad.animation.play('enter', true);
			else
				portraitDad.animation.play('enter', true,false,7);
			add(portraitDad);

			portraitDad.visible = true;
			if (portraitBoyfriend != null)
				portraitBoyfriend.visible = false;
		} else {
			if (portraitDad != null)
				portraitDad.visible = true;
			if (portraitBoyfriend == null)
				portraitBoyfriend = new FlxSprite(0, 40);

			portraitBoyfriend.frames = Paths.getAtlas('dialogue/$char');
			portraitBoyfriend.animation.addByPrefix('enter', 'slidein', 24, false);
			portraitBoyfriend.setGraphicSize(Std.int(portraitBoyfriend.width * PlayState.daPixelZoom * 0.9));
			portraitBoyfriend.updateHitbox();
			portraitBoyfriend.scrollFactor.set();
			add(portraitBoyfriend);

			if (lastDad != isDad)
				portraitBoyfriend.animation.play('enter', true);
			else
				portraitBoyfriend.animation.play('enter', true,false,7);

			portraitBoyfriend.visible = true;
			portraitDad.visible = false;
		}
		lastDad = isDad;
	}

	var portraitDad:FlxSprite;
	var portraitBoyfriend:FlxSprite;

	function end(?e) {
		kill();
		for (index => value in members) {
			value.destroy();
			remove(value, true);
		}
		finishCB();
		destroy();

		FlxG.state.remove(this, true);
	}

	override function destroy() {
		FlxG.sound.list.remove(sound, true);
		finishCB = null;
		text = FlxDestroyUtil.destroy(text);
		sound = FlxDestroyUtil.destroy(sound);
		box = FlxDestroyUtil.destroy(box);
		super.destroy();
	}

	var bgFade:FlxSprite;

	override function update(elapsed:Float) {
		if (bgFade.alpha > 0.7)
			bgFade.alpha = 0.7;
		super.update(elapsed);
		@:privateAccess
		if (PlayState.instance.controls.justPressed.UI_ACCEPT && !(curLine > dialogueJSON.dialogue.length - 1)) {
			nextDialog();
		}
	}
}

typedef DialogueFile = {
	var dialogue:Array<DialogueLine>;
}

typedef DialogueLine = {
	var portrait:Null<String>;
	var isDad:Null<Bool>;
	var text:Null<String>;
}
