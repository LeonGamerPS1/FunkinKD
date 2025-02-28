package funkin.states;

import funkin.objects.StrumLine;
import funkin.substates.EditorPlayState;
import funkin.objects.ChartSustain;
import funkin.objects.HealthIcon;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUITooltip.FlxUITooltipStyle;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.ui.FlxSpriteButton;
import flixel.util.FlxColor;
import haxe.Json;
import lime.utils.Assets;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.events.IOErrorEvent;
import openfl.events.IOErrorEvent;
import openfl.media.Sound;
import openfl.net.FileReference;
import openfl.utils.ByteArray;

using StringTools;

class ChartingState extends MusicBeatState {
	var _file:FileReference;

	var UI_box:FlxUITabMenu;

	/**
	 * Array of notes showing when each section STARTS in STEPS
	 * Usually rounded up??
	 */
	var curSection:Int = 0;

	public static var lastSection:Int = 0;

	var bpmTxt:FlxText;

	var strumLine:FlxSprite;
	var curSong:String = 'Dadbattle';
	var amountSteps:Int = 0;
	var bullshitUI:FlxGroup;

	var highlight:FlxSprite;

	var GRID_SIZE:Int = 40;

	var dummyArrow:FlxSprite;

	var curRenderedNotes:FlxTypedGroup<Note>;
	var curRenderedSustains:FlxTypedGroup<FlxSprite>;

	var gridBG:FlxSprite;

	var _song:SongData;

	var typingShit:FlxInputText;
	/*
	 * WILL BE THE CURRENT / LAST PLACED NOTE
	**/
	var curSelectedNote:Array<Dynamic>;
	var tempBpm:Float = 0;

	public var help:FlxSprite;

	var vocals:FlxSound;

	var leftIcon:HealthIcon;
	var rightIcon:HealthIcon;

	public var conductor:Conductor;
	public var leftStrums:StrumLine;
	public var rightStrums:StrumLine;
	public var noteTypeDropDown:FlxUIDropDownMenu;

	override function create() {
		curSection = lastSection;

		gridBG = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE * 8, GRID_SIZE * 16);
		add(gridBG);

		leftIcon = new HealthIcon('bf');
		rightIcon = new HealthIcon('dad');
		leftIcon.scrollFactor.set(1, 1);
		rightIcon.scrollFactor.set(1, 1);

		leftIcon.setGraphicSize(0, 45);
		rightIcon.setGraphicSize(0, 45);

		add(leftIcon);
		add(rightIcon);

		leftIcon.setPosition(0, -100);
		rightIcon.setPosition(gridBG.width / 2, -100);

		var gridBlackLine:FlxSprite = new FlxSprite(gridBG.x + gridBG.width / 2).makeGraphic(2, Std.int(gridBG.height), FlxColor.BLACK);
		add(gridBlackLine);

		curRenderedNotes = new FlxTypedGroup<Note>();
		curRenderedSustains = new FlxTypedGroup<FlxSprite>();

		if (PlayState.SONG != null)
			_song = PlayState.SONG;
		else
			_song = Song.dummy();

		for (section in _song.sections)
			if (section.lengthInSteps == null && Math.isNaN(section.lengthInSteps))
				section.lengthInSteps = 16;
			else
				continue;

		FlxG.mouse.visible = true;

		tempBpm = _song.bpm;
		conductor = new Conductor(tempBpm);
		addSection();

		// sections = _song.notes;

		updateGrid();

		loadSong(_song.song);

		conductor.changeBPM(_song.bpm);
		conductor.mapBPMChanges(_song);

		bpmTxt = new FlxText(1000, 50, 0, "", 16);
		bpmTxt.scrollFactor.set();
		add(bpmTxt);

		strumLine = new FlxSprite(0, 50).makeGraphic(Std.int(FlxG.width / 2), 4, FlxColor.GRAY);
		add(strumLine);

		dummyArrow = new FlxSprite().makeGraphic(GRID_SIZE, GRID_SIZE);
		add(dummyArrow);

		leftStrums = new StrumLine();
		leftStrums.y = 50;
		for (i in 0...4) {
			var strum = leftStrums.members[i];
			strum.setGraphicSize(GRID_SIZE, GRID_SIZE);
			strum.updateHitbox();
			strum.x = GRID_SIZE * strum.data;
		}

		rightStrums = new StrumLine();
		rightStrums.y = 50;
		for (i in 0...4) {
			var strum = rightStrums.members[i];
			strum.setGraphicSize(GRID_SIZE, GRID_SIZE);
			strum.updateHitbox();
			strum.x = GRID_SIZE * strum.data;
		}
		rightStrums.x += GRID_SIZE * 4;

		var tabs = [
			{name: "Song", label: 'Song'},
			{name: "Section", label: 'Section'},
			{name: "Note", label: 'Note'},

		];

		UI_box = new FlxUITabMenu(null, tabs, true);

		UI_box.resize(300, 400);
		UI_box.x = FlxG.width / 2;
		UI_box.y = 20;
		add(UI_box);

		addSongUI();
		addSectionUI();
		addNoteUI();

		add(curRenderedSustains);
		add(curRenderedNotes);
		add(rightStrums);
		add(leftStrums);

		help = new FlxSprite(0, 0, Paths.image("hp"));
		help.setGraphicSize(FlxG.width, FlxG.height);
		help.scrollFactor.set(0, 0);
		help.visible = false;
		add(help);

		super.create();
	}

	function addSongUI():Void {
		var UI_songTitle = new FlxUIInputText(10, 10, 70, _song.song, 8);
		typingShit = UI_songTitle;

		var check_mute_inst = new FlxUICheckBox(10, 200, null, null, "Mute Instrumental (in editor)", 100);
		check_mute_inst.checked = false;
		check_mute_inst.callback = function() {
			var vol:Float = 1;

			if (check_mute_inst.checked)
				vol = 0;

			FlxG.sound.music.volume = vol;
		};

		var saveButton:FlxButton = new FlxButton(110, 8, "Save", function() {
			saveLevel();
		});

		var reloadSong:FlxButton = new FlxButton(saveButton.x + saveButton.width + 10, saveButton.y, "Reload Audio", function() {
			loadSong(_song.song);
		});

		var reloadSongJson:FlxButton = new FlxButton(reloadSong.x, saveButton.y + 30, "Reload JSON", function() {
			loadJson(_song.song.toLowerCase());
		});

		var loadAutosaveBtn:FlxButton = new FlxButton(reloadSongJson.x, reloadSongJson.y + 30, 'load autosave', loadAutosave);

		var stepperSpeed:FlxUINumericStepper = new FlxUINumericStepper(10, 80, 0.1, 1, 0.1, 10, 1);
		stepperSpeed.value = _song.speed;
		stepperSpeed.name = 'song_speed';

		var stepperBPM:FlxUINumericStepper = new FlxUINumericStepper(10, 65, 1, 1, 1, 339, 0);
		stepperBPM.value = conductor.bpm;
		stepperBPM.name = 'song_bpm';

		var characters:Array<String> = CoolUtil.coolTextFile('assets/images/characterList.txt');

		var player1DropDown = new FlxUIDropDownMenu(10, 100, FlxUIDropDownMenu.makeStrIdLabelArray(characters, true), function(character:String) {
			_song.player1 = characters[Std.parseInt(character)];
		});
		player1DropDown.selectedLabel = _song.player1;

		var player2DropDown = new FlxUIDropDownMenu(140, 100, FlxUIDropDownMenu.makeStrIdLabelArray(characters, true), function(character:String) {
			_song.player2 = characters[Std.parseInt(character)];
		});

		player2DropDown.selectedLabel = _song.player2;

		var tab_group_song = new FlxUI(null, UI_box);
		tab_group_song.name = "Song";
		tab_group_song.add(UI_songTitle);

		tab_group_song.add(check_mute_inst);
		tab_group_song.add(saveButton);
		tab_group_song.add(reloadSong);
		tab_group_song.add(reloadSongJson);
		tab_group_song.add(loadAutosaveBtn);
		tab_group_song.add(stepperBPM);
		tab_group_song.add(stepperSpeed);
		tab_group_song.add(player1DropDown);
		tab_group_song.add(player2DropDown);

		UI_box.addGroup(tab_group_song);
		UI_box.scrollFactor.set();

		FlxG.camera.follow(strumLine);
	}

	var stepperLength:FlxUINumericStepper;
	var check_mustHitSection:FlxUICheckBox;
	var check_changeBPM:FlxUICheckBox;
	var stepperSectionBPM:FlxUINumericStepper;
	var check_altAnim:FlxUICheckBox;

	function addSectionUI():Void {
		var tab_group_section = new FlxUI(null, UI_box);
		tab_group_section.name = 'Section';

		stepperLength = new FlxUINumericStepper(10, 10, 4, 0, 0, 999, 0);
		stepperLength.value = _song.sections[curSection].lengthInSteps;
		stepperLength.name = "section_length";

		stepperSectionBPM = new FlxUINumericStepper(10, 80, 1, conductor.bpm, 0, 999, 0);
		stepperSectionBPM.value = conductor.bpm;
		stepperSectionBPM.name = 'section_bpm';

		var stepperCopy:FlxUINumericStepper = new FlxUINumericStepper(110, 130, 1, 1, -999, 999, 0);

		var copyButton:FlxButton = new FlxButton(10, 130, "Copy last section", function() {
			copySection(Std.int(stepperCopy.value));
		});

		var clearSectionButton:FlxButton = new FlxButton(10, 150, "Clear", clearSection);

		var swapSection:FlxButton = new FlxButton(10, 170, "Swap section", function() {
			for (i in 0..._song.sections[curSection].notes.length) {
				var note = _song.sections[curSection].notes[i];
				note[1] = (note[1] + 4) % 8;
				_song.sections[curSection].notes[i] = note;
				updateGrid();
			}
		});

		check_mustHitSection = new FlxUICheckBox(10, 30, null, null, "Must hit section", 100);
		check_mustHitSection.name = 'check_mustHit';
		check_mustHitSection.checked = true;
		// _song.needsVoices = check_mustHit.checked;

		check_altAnim = new FlxUICheckBox(10, 400, null, null, "Alt Animation", 100);
		check_altAnim.name = 'check_altAnim';

		check_changeBPM = new FlxUICheckBox(10, 60, null, null, 'Change BPM', 100);
		check_changeBPM.name = 'check_changeBPM';

		tab_group_section.add(stepperLength);
		tab_group_section.add(stepperSectionBPM);
		tab_group_section.add(stepperCopy);
		tab_group_section.add(check_mustHitSection);
		tab_group_section.add(check_altAnim);
		tab_group_section.add(check_changeBPM);
		tab_group_section.add(copyButton);
		tab_group_section.add(clearSectionButton);
		tab_group_section.add(swapSection);

		UI_box.addGroup(tab_group_section);
	}

	var stepperSusLength:FlxUINumericStepper;

	function loadSong(daSong:String):Void {
		if (FlxG.sound.music != null) {
			FlxG.sound.music.stop();
			// vocals.stop();
		}

		FlxG.sound.playMusic(Paths.inst(Paths.formatSongName(_song.song)), 0.6);

		// WONT WORK FOR TUTORIAL OR TEST SONG!!! REDO LATER
		vocals = new FlxSound().loadEmbedded(Paths.voices(Paths.formatSongName(_song.song)));
		FlxG.sound.list.add(vocals);

		FlxG.sound.music.pause();
		vocals.pause();

		FlxG.sound.music.onComplete = function() {
			vocals.pause();
			vocals.time = 0;
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
			changeSection();
		};
	}

	function generateUI():Void {
		while (bullshitUI.members.length > 0) {
			bullshitUI.remove(bullshitUI.members[0], true);
		}

		// general shit
		var title:FlxText = new FlxText(UI_box.x + 20, UI_box.y + 20, 0);
		bullshitUI.add(title);
		/* 
			var loopCheck = new FlxUICheckBox(UI_box.x + 10, UI_box.y + 50, null, null, "Loops", 100, ['loop check']);
			loopCheck.checked = curNoteSelected.doesLoop;
			tooltips.add(loopCheck, {title: 'Section looping', body: "Whether or not it's a simon says style section", style: tooltipType});
			bullshitUI.add(loopCheck);

		 */
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>) {
		if (id == FlxUICheckBox.CLICK_EVENT) {
			var check:FlxUICheckBox = cast sender;
			var label = check.getLabel().text;
			switch (label) {
				case 'Must hit section':
					_song.sections[curSection].cameraFacePlayer = check.checked;

					updateHeads();

				case 'Change BPM':
					_song.sections[curSection].changeBPM = check.checked;
					FlxG.log.add('changed bpm shit');
				case "Alt Animation":
					_song.sections[curSection].altSection = check.checked;
			}
		} else if (id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper)) {
			var nums:FlxUINumericStepper = cast sender;
			var wname = nums.name;
			FlxG.log.add(wname);
			if (wname == 'section_length') {
				_song.sections[curSection].lengthInSteps = Std.int(nums.value);
				updateGrid();
			} else if (wname == 'song_speed') {
				_song.speed = nums.value;
			} else if (wname == 'song_bpm') {
				tempBpm = Std.int(nums.value);
				conductor.mapBPMChanges(_song);
				conductor.changeBPM(nums.value);
			} else if (wname == 'note_susLength') {
				curSelectedNote[2] = nums.value;
				updateGrid();
			} else if (wname == 'section_bpm') {
				_song.sections[curSection].bpm = Std.int(nums.value);
				updateGrid();
			}
		} else if (id == FlxUIDropDownMenu.CLICK_EVENT && (sender is FlxUIDropDownMenu)) {
			var nums:FlxUIDropDownMenu = cast sender;
			var wname = nums.name;
			FlxG.log.add(wname);
			lastSelectedNType = nums.selectedLabel;
			if (wname == 'note_type') {
				if (curSelectedNote == null)
					return;

				trace("weed");
				curSelectedNote[3] = nums.selectedLabel;
				updateGrid();
			}
		}
		// FlxG.log.add(id + " WEED " + sender + " WEED " + data + " WEED " + params);
	}

	function addNoteUI():Void {
		var tab_group_note = new FlxUI(null, UI_box);
		tab_group_note.name = 'Note';

		stepperSusLength = new FlxUINumericStepper(10, 10, conductor.stepLength / 2, 0, 0, conductor.stepLength * 16);
		stepperSusLength.value = 0;
		stepperSusLength.name = 'note_susLength';

		var applyLength:FlxButton = new FlxButton(100, 10, 'Apply');

		tab_group_note.add(stepperSusLength);
		tab_group_note.add(applyLength);

		noteTypeDropDown = new FlxUIDropDownMenu(10, 50, FlxUIDropDownMenu.makeStrIdLabelArray(noteTypes, true));
		noteTypeDropDown.name = "note_type";
		tab_group_note.add(noteTypeDropDown);

		UI_box.addGroup(tab_group_note);
	}

	public var noteTypes:Array<String> = ["normal", "hurt"];

	var updatedSection:Bool = false;
	var lastSelectedNType:String = "";

	function sectionStartTime():Float {
		var daBPM:Float = _song.bpm;
		var daPos:Float = 0;
		for (i in 0...curSection) {
			if (_song.sections[i].changeBPM) {
				daBPM = _song.sections[i].bpm;
			}
			daPos += 4 * (1000 * 60 / daBPM);
		}
		return daPos;
	}

	var placeboi = false;

	override function update(elapsed:Float) {
		conductor.songPosition = FlxG.sound.music.time;

		conductor.update(elapsed);
		conductor.curStep = recalculateSteps();

		conductor.songPosition = FlxG.sound.music.time;
		_song.song = typingShit.text;

		strumLine.y = getYfromStrum((conductor.songPosition - sectionStartTime()) % (conductor.stepLength * 16));
		leftStrums.y = rightStrums.y = strumLine.y;

		if (conductor.curBeat % 4 == 0 && conductor.curStep >= 16 * (curSection + 1)) {
			if (_song.sections[curSection + 1] == null)
				addSection();

			changeSection(curSection + 1, false);
		}

		FlxG.watch.addQuick('daBeat', conductor.curBeat);
		FlxG.watch.addQuick('daStep', conductor.curStep);

		if (FlxG.mouse.justPressed) {
			if (FlxG.mouse.overlaps(curRenderedNotes)) {
				curRenderedNotes.forEach(function(note:Note) {
					if (FlxG.mouse.overlaps(note)) {
						if (FlxG.keys.pressed.CONTROL) {
							selectNote(note);
						} else {
							trace('tryin to delete note...');
							placeboi = true;
							deleteNote(note);
						}
					}
				});
			} else {
				if (FlxG.mouse.x > gridBG.x
					&& FlxG.mouse.x < gridBG.x + gridBG.width
					&& FlxG.mouse.y > gridBG.y
					&& FlxG.mouse.y < gridBG.y + (GRID_SIZE * 16)) {
					FlxG.log.add('added note');
					addNote();
					placeboi = true;
				}
			}
		}

		if (FlxG.mouse.x > gridBG.x
			&& FlxG.mouse.x < gridBG.x + gridBG.width
			&& FlxG.mouse.y > gridBG.y
			&& FlxG.mouse.y < gridBG.y + (GRID_SIZE * 16)) {
			dummyArrow.x = Math.floor(FlxG.mouse.x / GRID_SIZE) * GRID_SIZE;
			if (FlxG.keys.pressed.SHIFT)
				dummyArrow.y = FlxG.mouse.y;
			else
				dummyArrow.y = Math.floor(FlxG.mouse.y / GRID_SIZE) * GRID_SIZE;
		}

		curRenderedNotes.forEach(function(note:Note) {
			if (note.time <= conductor.songPosition) {
				if (!note.wasGoodHit && !placeboi) {
					playStrumAnim(note);
					note.wasGoodHit = true;
				}
				note.alpha = 0.7;
			} else {
				note.alpha = 1;
				if (note.wasGoodHit)
					note.wasGoodHit = false;
			}
		});

		placeboi = false;
		if (FlxG.keys.justPressed.ENTER) {
			lastSection = curSection;

			PlayState.SONG = _song;
			FlxG.sound.music.stop();
			vocals.stop();
			FlxG.switchState(new PlayState());
		}

		if (FlxG.keys.pressed.E)
			changeNoteSustain(conductor.stepLength / 4);

		if (FlxG.keys.pressed.Q)
			changeNoteSustain(-conductor.stepLength / 4);

		if (FlxG.keys.justPressed.TAB) {
			if (FlxG.keys.pressed.SHIFT) {
				UI_box.selected_tab -= 1;
				if (UI_box.selected_tab < 0)
					UI_box.selected_tab = 2;
			} else {
				UI_box.selected_tab += 1;
				if (UI_box.selected_tab >= 3)
					UI_box.selected_tab = 0;
			}
		}

		if (!typingShit.hasFocus) {
			if (FlxG.keys.justPressed.SPACE) {
				if (FlxG.sound.music.playing) {
					FlxG.sound.music.pause();
					vocals.pause();
				} else {
					vocals.play();
					FlxG.sound.music.play();
				}
			}

			if (FlxG.keys.justPressed.R) {
				if (FlxG.keys.pressed.SHIFT)
					resetSection(true);
				else
					resetSection();
			}

			if (FlxG.mouse.wheel != 0) {
				FlxG.sound.music.pause();
				vocals.pause();

				FlxG.sound.music.time -= (FlxG.mouse.wheel * conductor.stepLength * 0.4);
				vocals.time = FlxG.sound.music.time;
			}

			if (!FlxG.keys.pressed.SHIFT) {
				if (FlxG.keys.pressed.W || FlxG.keys.pressed.S) {
					FlxG.sound.music.pause();
					vocals.pause();

					var daTime:Float = 700 * FlxG.elapsed;

					if (FlxG.keys.pressed.W) {
						FlxG.sound.music.time -= daTime;
					} else
						FlxG.sound.music.time += daTime;

					vocals.time = FlxG.sound.music.time;
				}
			} else {
				if (FlxG.keys.justPressed.W || FlxG.keys.justPressed.S) {
					FlxG.sound.music.pause();
					vocals.pause();

					var daTime:Float = conductor.stepLength * 2;

					if (FlxG.keys.justPressed.W) {
						FlxG.sound.music.time -= daTime;
					} else
						FlxG.sound.music.time += daTime;

					vocals.time = FlxG.sound.music.time;
				}
			}
		}

		_song.bpm = tempBpm;

		var shiftThing:Int = 1;
		if (FlxG.keys.pressed.SHIFT)
			shiftThing = 4;
		if (FlxG.keys.justPressed.RIGHT || FlxG.keys.justPressed.D)
			changeSection(curSection + shiftThing);
		if (FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.A)
			changeSection(curSection - shiftThing);

		bpmTxt.text = bpmTxt.text = Std.string(FlxMath.roundDecimal(conductor.songPosition / 1000, 2))
			+ " / "
			+ Std.string(FlxMath.roundDecimal(FlxG.sound.music.length / 1000, 2))
			+ "\nSection: "
			+ curSection;

		super.update(elapsed);

		if (FlxG.keys.justPressed.F1)
			help.visible = !help.visible;
		if (FlxG.keys.justPressed.ESCAPE)
			FlxG.switchState(new EditorPlayState(_song));
	}

	public inline function playStrumAnim(note:Note) {
		var sl:StrumLine = note.data > 3 ? rightStrums : leftStrums;

		sl.members[note.data % sl.length].playAnim("confirm", true);
		sl.members[note.data % sl.length].resetTimer = Math.max(conductor.stepLength * 1.25, note.length) / 1000;
	}

	function changeNoteSustain(value:Float):Void {
		if (curSelectedNote != null) {
			if (curSelectedNote[2] != null) {
				curSelectedNote[2] += value;
				curSelectedNote[2] = Math.max(curSelectedNote[2], 0);
			}
		}

		updateNoteUI();
		updateGrid();
	}

	function recalculateSteps():Int {
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}
		for (i in 0...conductor.bpmChangeMap.length) {
			if (FlxG.sound.music.time > conductor.bpmChangeMap[i].songTime)
				lastChange = conductor.bpmChangeMap[i];
		}

		conductor.curStep = lastChange.stepTime + Math.floor((FlxG.sound.music.time - lastChange.songTime) / conductor.stepLength);
		@:privateAccess
		conductor.updateBeat();

		return conductor.curStep;
	}

	function resetSection(songBeginning:Bool = false):Void {
		updateGrid();

		FlxG.sound.music.pause();
		vocals.pause();

		// Basically old shit from changeSection???
		FlxG.sound.music.time = sectionStartTime();

		if (songBeginning) {
			FlxG.sound.music.time = 0;
			curSection = 0;
		}

		vocals.time = FlxG.sound.music.time;
		@:privateAccess
		conductor.updateStep();

		updateGrid();
		updateSectionUI();
	}

	function changeSection(sec:Int = 0, ?updateMusic:Bool = true):Void {
		trace('changing section' + sec);

		if (_song.sections[sec] != null) {
			curSection = sec;

			updateGrid();

			if (updateMusic) {
				FlxG.sound.music.pause();
				vocals.pause();

				FlxG.sound.music.time = sectionStartTime();
				vocals.time = FlxG.sound.music.time;
				@:privateAccess
				conductor.updateStep();
			}

			updateGrid();
			updateSectionUI();
		}
	}

	function copySection(?sectionNum:Int = 1) {
		var daSec = FlxMath.maxInt(curSection, sectionNum);

		for (note in _song.sections[daSec - sectionNum].notes) {
			var strum = note[0] + conductor.stepLength * (16 * sectionNum);

			var copiedNote:Array<Dynamic> = [strum, note[1], note[2]];
			_song.sections[daSec].notes.push(copiedNote);
		}

		updateGrid();
	}

	function updateSectionUI():Void {
		var sec = _song.sections[curSection];

		stepperLength.value = 16;
		check_mustHitSection.checked = sec.cameraFacePlayer;
		check_altAnim.checked = sec.altSection;
		check_changeBPM.checked = sec.changeBPM;
		stepperSectionBPM.value = sec.bpm;

		updateHeads();
	}

	function updateHeads():Void {}

	function updateNoteUI():Void {
		if (curSelectedNote != null)
			stepperSusLength.value = curSelectedNote[2];
	}

	function updateGrid():Void {
		while (curRenderedNotes.members.length > 0) {
			curRenderedNotes.remove(curRenderedNotes.members[0], true);
		}

		while (curRenderedSustains.members.length > 0) {
			curRenderedSustains.remove(curRenderedSustains.members[0], true);
		}

		var sectionInfo:Array<Dynamic> = _song.sections[curSection].notes;

		if (_song.sections[curSection].changeBPM && _song.sections[curSection].bpm > 0) {
			conductor.changeBPM(_song.sections[curSection].bpm);
			FlxG.log.add('CHANGED BPM!');
		} else {
			// get last bpm
			var daBPM:Float = _song.bpm;
			for (i in 0...curSection)
				if (_song.sections[i].changeBPM)
					daBPM = _song.sections[i].bpm;
			conductor.changeBPM(daBPM);
		}

		for (i in sectionInfo) {
			var daNoteInfo = i[1];
			var daStrumTime = i[0];
			var daSus = i[2];
			var daSusType = i[3] == null ? "normal" : i[3];

			var note:Note = new Note(daStrumTime, daNoteInfo % 4, PlayState.isPixelStage, null, 1, conductor, daSusType);
			note.length = daSus;
			note.setGraphicSize(GRID_SIZE, GRID_SIZE);
			note.updateHitbox();
			note.x = Math.floor(daNoteInfo * GRID_SIZE);
			note.y = Math.floor(getYfromStrum((daStrumTime - sectionStartTime()) % (conductor.stepLength * 16)));
			note.inEditor = true;

			curRenderedNotes.add(note);

			if (daSus > 0) {
				var sustainVis:ChartSustain = new ChartSustain(note, gridBG, daSus);
				curRenderedSustains.add(sustainVis); // sustains go brrr
			}
			note.data = daNoteInfo; // the sustains freak out with the tiling if notedata is above 4 and note deletion kinda breaks if i remove this line
		}
	}

	private function addSection(lengthInSteps:Int = 16):Void {
		var sec:Section = {
			lengthInSteps: lengthInSteps,
			bpm: _song.bpm,
			changeBPM: false,
			cameraFacePlayer: true,
			notes: [],
			altSection: false
		};

		_song.sections.push(sec);
	}

	function selectNote(note:Note):Void {
		var swagNum:Int = 0;

		for (i in _song.sections[curSection].notes) {
			if (i[0] == note.time && i[1] % 4 == note.data)
				curSelectedNote = _song.sections[curSection].notes[swagNum];

			swagNum += 1;
		}

		updateGrid();
		updateNoteUI();
	}

	function deleteNote(note:Note):Void {
		for (i in _song.sections[curSection].notes) {
			if (i[0] == note.time && i[1] == note.data) {
				FlxG.log.add('FOUND EVIL NUMBER');
				_song.sections[curSection].notes.remove(i);
			}
		}

		updateGrid();
	}

	function clearSection():Void {
		_song.sections[curSection].notes = [];

		updateGrid();
	}

	function clearSong():Void {
		for (daSection in 0..._song.sections.length) {
			_song.sections[daSection].notes = [];
		}

		updateGrid();
	}

	private function addNote():Void {
		var noteStrum = getStrumTime(dummyArrow.y) + sectionStartTime();
		var noteData = Math.floor(FlxG.mouse.x / GRID_SIZE);
		var noteSus = 0;
		var noteSusType = lastSelectedNType;

		_song.sections[curSection].notes.push([noteStrum, noteData, noteSus, noteSusType]);

		curSelectedNote = _song.sections[curSection].notes[_song.sections[curSection].notes.length - 1];

		if (FlxG.keys.pressed.CONTROL)
			_song.sections[curSection].notes.push([noteStrum, (noteData + 4) % 8, noteSus]);

		updateGrid();
		updateNoteUI();

		autosaveSong();
	}

	function getStrumTime(yPos:Float):Float {
		return FlxMath.remapToRange(yPos, gridBG.y, gridBG.y + gridBG.height, 0, 16 * conductor.stepLength);
	}

	function getYfromStrum(strumTime:Float):Float {
		return FlxMath.remapToRange(strumTime, 0, 16 * conductor.stepLength, gridBG.y, gridBG.y + gridBG.height);
	}

	private var daSpacing:Float = 0.3;

	function getNotes():Array<Dynamic> {
		var noteData:Array<Dynamic> = [];

		for (i in _song.sections)
			noteData.push(i.notes);

		return noteData;
	}

	function loadJson(song:String):Void {
		PlayState.SONG = Song.parseSong(Paths.formatSongName(song), PlayState.weekDifficulty.toLowerCase());
		FlxG.resetState();
	}

	function loadAutosave():Void {
		PlayState.SONG = Song.parseJSONshit(FlxG.save.data.autosave);
		FlxG.resetState();
	}

	function autosaveSong():Void {
		FlxG.save.data.autosave = Json.stringify({
			"song": _song
		});
		FlxG.save.flush();
	}

	private function saveLevel() {
		var json = {
			"song": _song
		};

		var data:String = Json.stringify(json);

		if ((data != null) && (data.length > 0)) {
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data.trim(), _song.song.toLowerCase() + ".json");
		}
	}

	function onSaveComplete(_):Void {
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved LEVEL DATA.");
	}

	/**
	 * Called when the save file dialog is cancelled.
	 */
	function onSaveCancel(_):Void {
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	/**
	 * Called if there is an error while saving the gameplay recording.
	 */
	function onSaveError(_):Void {
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving Level data");
	}
}
