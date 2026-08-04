import io.newgrounds.objects.Medal;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.DisplayObject;
import openfl.display.Loader;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.events.SecurityErrorEvent;
import openfl.net.URLRequest;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;

private typedef MedalPopupEntry =
{
	var name:String;
	var value:Int;
	var description:String;
	var icon:String;
}

/**
 * Self-contained medal notification for the Stencyl Newgrounds.IO extension.
 *
 * Text is rasterized into BitmapData before being added to the display list.
 * This avoids an HTML5/Stencyl target issue where OpenFL TextField objects exist
 * but do not render when attached directly to Engine.stage.
 */
class StencylNGMedalPopup extends Sprite
{
	private static inline var POPUP_WIDTH:Float = 380;
	private static inline var POPUP_HEIGHT:Float = 138;
	private static inline var SCREEN_MARGIN:Float = 12;
	private static inline var ENTER_TIME:Float = 0.25;
	private static inline var HOLD_TIME:Float = 4.0;
	private static inline var EXIT_TIME:Float = 0.25;

	private var background:Shape;
	private var iconHolder:Sprite;
	private var fallbackIcon:Sprite;
	private var titleBitmap:Bitmap;
	private var nameBitmap:Bitmap;
	private var pointsBitmap:Bitmap;
	private var descriptionBitmap:Bitmap;

	private var queue:Array<MedalPopupEntry>;
	private var active:Bool;
	private var state:Int;
	private var stateStarted:Float;
	private var loader:Loader;
	private var popupPosition:String = "top-right";
	private var targetX:Float;
	private var targetY:Float;
	private var enterX:Float;
	private var enterY:Float;
	private var exitStartX:Float;
	private var exitStartY:Float;
	private var exitX:Float;
	private var exitY:Float;

	public function new()
	{
		super();

		mouseEnabled = false;
		mouseChildren = false;
		queue = [];
		active = false;
		visible = false;

		buildDisplay();
		addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
	}

	public function showMedal(medal:Medal):Void
	{
		if (medal == null)
		{
			return;
		}

		queue.push({
			name: medal.name,
			value: medal.value,
			description: medal.description,
			icon: medal.icon
		});

		if (!active)
		{
			showNext();
		}
	}

	/**
	 * Accepts one of the nine values exposed by the Stencyl dropdown block:
	 * top-left, top-middle, top-right, middle-left, center, middle-right,
	 * bottom-left, bottom-middle, or bottom-right.
	 */
	public function setPosition(position:String):Void
	{
		popupPosition = normalizePosition(position);

		// Reposition immediately while the popup is resting on screen.
		// Enter/exit animations keep their current path and the next popup uses
		// the newly selected position from the beginning.
		if (stage != null && visible && state == 1)
		{
			calculateTargetPosition();
			x = targetX;
			y = targetY;
		}
	}

	private function normalizePosition(position:String):String
	{
		return switch (position)
		{
			case "top-left", "top-middle", "top-right",
				 "middle-left", "center", "middle-right",
				 "bottom-left", "bottom-middle", "bottom-right":
				position;
			default:
				"top-right";
		}
	}

	private function buildDisplay():Void
	{
		background = new Shape();
		background.graphics.lineStyle(2, 0xF6C343, 1);
		background.graphics.beginFill(0x171717, 0.96);
		background.graphics.drawRoundRect(0, 0, POPUP_WIDTH, POPUP_HEIGHT, 12, 12);
		background.graphics.endFill();
		addChild(background);

		iconHolder = new Sprite();
		iconHolder.x = 12;
		iconHolder.y = 12;
		addChild(iconHolder);

		fallbackIcon = createFallbackIcon();
		iconHolder.addChild(fallbackIcon);

		titleBitmap = createTextBitmap("MEDAL UNLOCKED", 278, 24, 18, true, 0xF6C343, false, false);
		titleBitmap.x = 88;
		titleBitmap.y = 9;
		addChild(titleBitmap);
	}

	private function createTextBitmap(
		text:String,
		width:Int,
		height:Int,
		size:Int,
		bold:Bool,
		color:Int,
		multiline:Bool,
		wordWrap:Bool
	):Bitmap
	{
		var safeText = text == null ? "" : text;
		var field = new TextField();
		var format = new TextFormat("_sans", size, color, bold, null, null, null, null, TextFormatAlign.LEFT);

		field.width = width;
		field.height = height;
		field.embedFonts = false;
		field.selectable = false;
		field.mouseEnabled = false;
		field.multiline = multiline;
		field.wordWrap = wordWrap;
		field.autoSize = TextFieldAutoSize.NONE;
		field.textColor = color;
		field.defaultTextFormat = format;
		field.text = safeText;
		field.setTextFormat(format);

		var bitmapData = new BitmapData(width, height, true, 0x00000000);
		bitmapData.draw(field);

		var bitmap = new Bitmap(bitmapData);
		bitmap.smoothing = true;
		return bitmap;
	}

	private function createFallbackIcon():Sprite
	{
		var icon = new Sprite();
		icon.graphics.lineStyle(3, 0xFFF0A0, 1);
		icon.graphics.beginFill(0xD99A16, 1);
		icon.graphics.drawCircle(32, 32, 29);
		icon.graphics.endFill();

		// Vector-only center mark so the fallback does not depend on TextField rendering.
		icon.graphics.lineStyle(4, 0x171717, 1);
		icon.graphics.moveTo(21, 41);
		icon.graphics.lineTo(21, 23);
		icon.graphics.lineTo(43, 41);
		icon.graphics.lineTo(43, 23);
		return icon;
	}

	private function showNext():Void
	{
		if (queue.length == 0)
		{
			active = false;
			visible = false;
			removeEventListener(Event.ENTER_FRAME, updateAnimation);
			return;
		}

		active = true;
		visible = true;
		alpha = 0;
		state = 0;
		stateStarted = haxe.Timer.stamp();

		var entry = queue.shift();
		rebuildMedalText(entry.name, entry.value, entry.description);
		resetIcon();
		loadIcon(entry.icon);
		positionPopup();

		if (parent != null)
		{
			parent.setChildIndex(this, parent.numChildren - 1);
		}

		removeEventListener(Event.ENTER_FRAME, updateAnimation);
		addEventListener(Event.ENTER_FRAME, updateAnimation);
	}

	private function rebuildMedalText(medalName:String, medalValue:Int, medalDescription:String):Void
	{
		removeBitmap(nameBitmap);
		removeBitmap(pointsBitmap);
		removeBitmap(descriptionBitmap);

		var safeName = medalName == null || medalName == "" ? "Unnamed Medal" : medalName;
		var pointsText = Std.string(medalValue) + (medalValue == 1 ? " point" : " points");
		var safeDescription = medalDescription == null || medalDescription == ""
			? "No description provided."
			: medalDescription;

		nameBitmap = createTextBitmap(safeName, 278, 24, 16, true, 0xFFFFFF, false, false);
		nameBitmap.x = 88;
		nameBitmap.y = 34;
		addChild(nameBitmap);

		pointsBitmap = createTextBitmap(pointsText, 278, 20, 13, false, 0xD7D7D7, false, false);
		pointsBitmap.x = 88;
		pointsBitmap.y = 58;
		addChild(pointsBitmap);

		descriptionBitmap = createTextBitmap(safeDescription, 278, 48, 12, false, 0xEAEAEA, true, true);
		descriptionBitmap.x = 88;
		descriptionBitmap.y = 80;
		addChild(descriptionBitmap);
	}

	private function removeBitmap(bitmap:Bitmap):Void
	{
		if (bitmap == null)
		{
			return;
		}

		if (bitmap.parent == this)
		{
			removeChild(bitmap);
		}

		if (bitmap.bitmapData != null)
		{
			bitmap.bitmapData.dispose();
			bitmap.bitmapData = null;
		}
	}

	private function positionPopup():Void
	{
		if (stage == null)
		{
			return;
		}

		calculateTargetPosition();
		calculateEnterPosition();
		x = enterX;
		y = enterY;
	}

	private function calculateTargetPosition():Void
	{
		var leftX = SCREEN_MARGIN;
		var middleX = Math.max(0, (stage.stageWidth - POPUP_WIDTH) * 0.5);
		var rightX = Math.max(SCREEN_MARGIN, stage.stageWidth - POPUP_WIDTH - SCREEN_MARGIN);
		var topY = SCREEN_MARGIN;
		var middleY = Math.max(0, (stage.stageHeight - POPUP_HEIGHT) * 0.5);
		var bottomY = Math.max(SCREEN_MARGIN, stage.stageHeight - POPUP_HEIGHT - SCREEN_MARGIN);

		switch (popupPosition)
		{
			case "top-left":
				targetX = leftX;
				targetY = topY;
			case "top-middle":
				targetX = middleX;
				targetY = topY;
			case "middle-left":
				targetX = leftX;
				targetY = middleY;
			case "center":
				targetX = middleX;
				targetY = middleY;
			case "middle-right":
				targetX = rightX;
				targetY = middleY;
			case "bottom-left":
				targetX = leftX;
				targetY = bottomY;
			case "bottom-middle":
				targetX = middleX;
				targetY = bottomY;
			case "bottom-right":
				targetX = rightX;
				targetY = bottomY;
			default: // top-right
				targetX = rightX;
				targetY = topY;
		}
	}

	private function calculateEnterPosition():Void
	{
		enterX = targetX;
		enterY = targetY;

		switch (popupPosition)
		{
			case "top-left", "top-middle", "top-right":
				enterY = -POPUP_HEIGHT;
			case "bottom-left", "bottom-middle", "bottom-right":
				enterY = stage.stageHeight;
			case "middle-left":
				enterX = -POPUP_WIDTH;
			case "middle-right":
				enterX = stage.stageWidth;
			case "center":
				enterY = targetY - 20;
		}
	}

	private function calculateExitPosition():Void
	{
		exitX = targetX;
		exitY = targetY;

		switch (popupPosition)
		{
			case "top-left", "top-middle", "top-right":
				exitY = -POPUP_HEIGHT;
			case "bottom-left", "bottom-middle", "bottom-right":
				exitY = stage.stageHeight;
			case "middle-left":
				exitX = -POPUP_WIDTH;
			case "middle-right":
				exitX = stage.stageWidth;
			case "center":
				exitY = targetY - 20;
		}
	}

	private function updateAnimation(event:Event):Void
	{
		if (stage == null)
		{
			return;
		}

		var elapsed = haxe.Timer.stamp() - stateStarted;

		switch (state)
		{
			case 0:
				var enterProgress = clamp01(elapsed / ENTER_TIME);
				var easedEnter = easeOutCubic(enterProgress);
				alpha = enterProgress;
				x = lerp(enterX, targetX, easedEnter);
				y = lerp(enterY, targetY, easedEnter);

				if (enterProgress >= 1)
				{
					state = 1;
					stateStarted = haxe.Timer.stamp();
					alpha = 1;
					x = targetX;
					y = targetY;
				}

			case 1:
				// Keep the selected anchor correct if the browser or game stage resizes.
				calculateTargetPosition();
				x = targetX;
				y = targetY;

				if (elapsed >= HOLD_TIME)
				{
					state = 2;
					stateStarted = haxe.Timer.stamp();
					exitStartX = x;
					exitStartY = y;
					calculateExitPosition();
				}

			case 2:
				var exitProgress = clamp01(elapsed / EXIT_TIME);
				var easedExit = easeInCubic(exitProgress);
				alpha = 1 - exitProgress;
				x = lerp(exitStartX, exitX, easedExit);
				y = lerp(exitStartY, exitY, easedExit);

				if (exitProgress >= 1)
				{
					showNext();
				}
		}
	}

	private function resetIcon():Void
	{
		if (loader != null)
		{
			loader.removeEventListener(Event.COMPLETE, onIconLoaded);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onIconLoadFailed);
			loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onIconLoadFailed);
			loader = null;
		}

		while (iconHolder.numChildren > 0)
		{
			iconHolder.removeChildAt(0);
		}

		fallbackIcon = createFallbackIcon();
		iconHolder.addChild(fallbackIcon);
	}

	private function loadIcon(iconUrl:String):Void
	{
		if (iconUrl == null || iconUrl == "")
		{
			return;
		}

		loader = new Loader();
		loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onIconLoaded);
		loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onIconLoadFailed);
		loader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onIconLoadFailed);

		try
		{
			loader.load(new URLRequest(iconUrl));
		}
		catch (error:Dynamic)
		{
			onIconLoadFailed(null);
		}
	}

	private function onIconLoaded(event:Event):Void
	{
		if (loader == null)
		{
			return;
		}

		var content:DisplayObject = loader.content;
		if (content == null)
		{
			onIconLoadFailed(null);
			return;
		}

		while (iconHolder.numChildren > 0)
		{
			iconHolder.removeChildAt(0);
		}

		var scale = Math.min(64 / content.width, 64 / content.height);
		content.scaleX = scale;
		content.scaleY = scale;
		content.x = (64 - content.width) * 0.5;
		content.y = (64 - content.height) * 0.5;
		iconHolder.addChild(content);
		clearLoaderListeners();
	}

	private function onIconLoadFailed(event:Event):Void
	{
		clearLoaderListeners();
	}

	private function clearLoaderListeners():Void
	{
		if (loader == null)
		{
			return;
		}

		loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onIconLoaded);
		loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onIconLoadFailed);
		loader.contentLoaderInfo.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onIconLoadFailed);
		loader = null;
	}

	private function onRemovedFromStage(event:Event):Void
	{
		removeEventListener(Event.ENTER_FRAME, updateAnimation);
		clearLoaderListeners();
		removeBitmap(nameBitmap);
		removeBitmap(pointsBitmap);
		removeBitmap(descriptionBitmap);
		removeBitmap(titleBitmap);
	}

	private inline function lerp(startValue:Float, endValue:Float, amount:Float):Float
	{
		return startValue + ((endValue - startValue) * amount);
	}

	private inline function clamp01(value:Float):Float
	{
		return value < 0 ? 0 : (value > 1 ? 1 : value);
	}

	private inline function easeOutCubic(value:Float):Float
	{
		var inverse = 1 - value;
		return 1 - (inverse * inverse * inverse);
	}

	private inline function easeInCubic(value:Float):Float
	{
		return value * value * value;
	}
}
