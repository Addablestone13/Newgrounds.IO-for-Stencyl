import io.newgrounds.NG;
import io.newgrounds.objects.Error;
import io.newgrounds.objects.Medal;
import io.newgrounds.objects.ScoreBoard;
import io.newgrounds.objects.Score;
import io.newgrounds.objects.events.Response;
import io.newgrounds.objects.events.Result.ScoreResult;
import io.newgrounds.components.ScoreBoardComponent.Period;
import com.stencyl.Engine;

class StencylNG
{
	public static var unlockCallback:Medal->Void;
	public static var debug:Bool = false;
	public static var medalPopup:StencylNGMedalPopup;
	public static var medalPopupPosition:String = "top-right";

	public static var leaderboardScores:Array<Score> = [];
	public static var leaderboardLoaded:Bool = false;
	public static var leaderboardLoading:Bool = false;
	public static var leaderboardError:String = "";
	public static var leaderboardScoreboardName:String = "";
	public static var leaderboardBoardID:Int = -1;
	public static var leaderboardSkip:Int = 0;
	public static var leaderboardCallback:Void->Void;
	public static var leaderboardErrorCallback:Void->Void;

	public static function init(appID:String, encryptionKey:String, debugMode:Bool)
	{
		if (NG.core != null)
		{
			trace("NG core has already been started.");
			return;
		}
	
		trace("NG starting.");
		debug = debugMode;
		NG.createAndCheckSession(appID, debugMode, null, onSessionFail);
		NG.core.encryptionHandler = io.newgrounds.crypto.AesEncryption.create(encryptionKey);
		initMedalPopup();
	}

	private static function initMedalPopup():Void
	{
		if (medalPopup != null)
		{
			return;
		}

		if (Engine.stage == null)
		{
			trace("Newgrounds medal popup could not be added because the Stencyl stage is not ready.");
			return;
		}

		medalPopup = new StencylNGMedalPopup();
		medalPopup.setPosition(medalPopupPosition);
		Engine.stage.addChild(medalPopup);
	}
	
	private static function showMedalPopup(medal:Medal):Void
	{
		if (medalPopup == null)
		{
			initMedalPopup();
		}

		if (medalPopup != null)
		{
			medalPopup.showMedal(medal);
		}
	}

	/**
	 * Sets where medal notifications appear on the game stage.
	 * This can be called before or after Newgrounds initialization.
	 */
	public static function setMedalPopupPosition(position:String):Void
	{
		medalPopupPosition = position;

		if (medalPopup != null)
		{
			medalPopup.setPosition(position);
		}
	}

	public static function login()
	{
		if (NG.core == null)
		{
			trace("NG core has not been started.");
			return;
		}
	
		if (NG.core.loggedIn)
		{
			trace("Already logged in.");
		}
		else
		{
			NG.core.requestLogin(function():Void { trace("Logged in."); });
		}
	}
	
	public static function unlockMedal(id:Float)
	{
		if (NG.core == null)
		{
			trace("NG core has not been started.");
			return;
		}
		if (!NG.core.loggedIn)
		{
			trace("Not logged in.");
			return;
		}
		if (NG.core.sessionId == null)
		{
			trace("Session ID not found.");
			return;
		}
	
		var idInt = Std.int(id);
		
		if (NG.core.medals == null)
		{
			NG.core.requestMedals(function ():Void { sendUnlock(idInt); });
		}
		else
		{
			sendUnlock(idInt);
		}	
	}
	
	public static function sendUnlock(id:Int)
	{
		var medal:Medal = NG.core.medals.get(id);
		//trace(medal.toString());

		if (medal.unlocked && !debug)
		{
			trace("Medal is already unlocked.");
		}
		else
		{
			medal.onUnlock.addOnce(function ():Void
			{
				showMedalPopup(medal);
				trace('${medal.name} unlocked:${medal.unlocked}');

				if (unlockCallback != null)
				{
					unlockCallback(medal);
				}
			});
			
			if (debug)
			{
				medal.sendDebugUnlock();
			}
			else
			{
				medal.sendUnlock();
			}
		}
	}
	
	public static function isUserLoggedIn():Bool
	{
		return NG.core != null && NG.core.loggedIn;
	}
	
	public static function isLoggedIn():Bool
	{
		return getUsername() != null && getUsername() != "";
	}

	public static function setUnlockCallback(callbackFn:Medal->Void)
	{
		unlockCallback = callbackFn;
	}
	
	public static function getMedalProperty(type:String, object:Dynamic):Dynamic
	{
		if (NG.core == null)
		{
			trace("NG core has not been started.");
			return null;
		}
	
		var medal:Medal = null;
	
		if (Std.is(object, Medal))
		{
			medal = object;
		}
		else
		{
			trace("Object is not a medal.");
			return null;
		}
	
		if (medal == null)
		{
			trace("Medal is null.");
			return null;
		}
	
		if (type == "id")
		{
			return medal.id;
		}
		else if (type == "name")
		{
			return medal.name;
		}
		else if (type == "description")
		{
			return medal.description;
		}
		else if (type == "icon")
		{
			return medal.icon;
		}
		else if (type == "value")
		{
			return medal.value;
		}
		else if (type == "difficulty")
		{
			return medal.difficultyName;
		}
		else if (type == "secret")
		{
			return medal.secret;
		}
		else if (type == "unlocked")
		{
			return medal.unlocked;
		}
		else
		{
			trace("Invalid medal property.");
			return null;
		}
	}
	
	public static function onSessionFail(error:Error)
	{
		trace("Session failed.");
	}

	public static function onMedalSuccess()
	{
		trace("Medals found.");
	}

	public static function onMedalFail()
	{
		trace("Failed to find medals.");
	}

	public static function getUsername():String
	{
		if (NG.core == null)
		{
			trace("NG core not initialized.");
			return null;
		}

		if (!NG.core.loggedIn)
		{
			trace("User not logged in.");
			return null;
		}

		if (NG.core.user == null)
		{
			trace("User data not available.");
			return null;
		}

		return NG.core.user.name;
	}

	public static function submitScore(boardID:Int, score:Int)
	{
		if (NG.core == null)
		{
			trace("NG core not initialized.");
			return;
		}
		
		if (!NG.core.loggedIn)
		{
			trace("User not logged in.");
			return;
		}
		
		if (NG.core.scoreBoards == null)
		{
			trace("Scoreboards not loaded, loading now.");
			NG.core.requestScoreBoards(function()
			{
				submitScore(boardID, score);
			});
			return;
		}
		
		var board = NG.core.scoreBoards.get(boardID);
		if (board == null)
		{
			trace("Scoreboard ID " + boardID + " not found.");
			return;
		}
		
		trace("Submitting score " + score + " to board " + boardID);
		
		board.scorePostedCallback = function(response)
		{
			trace("Raw response: " + Std.string(response));

			if (response.success)
			{
				trace("Score posted successfully!");
			}
			else if (response.result != null && response.result.message != null)
			{
				trace("Failed to post score: " + response.result.message);
			}
			else
			{
				trace("Failed to post score: No message");
			}
		};

		board.postScore(score);
	}

	public static function loadScoreboardsAndSubmitScore(boardID:Int, score:Int):Void
	{
		if (NG.core == null)
		{
			trace("NG core not initialized.");
			return;
		}
		if (!NG.core.loggedIn)
		{
			trace("User not logged in.");
			return;
		}
		if (NG.core.scoreBoards != null)
		{
			// Already loaded, submit immediately
			submitScore(boardID, score);
		}
		else
		{
			trace("Scoreboards not loaded, loading now.");
			NG.core.requestScoreBoards(function()
			{
				trace("Scoreboards loaded.");
				submitScore(boardID, score);
			});
		}
	}

	/**
	 * Fetches a ranked page of scores from a Newgrounds scoreboard.
	 *
	 * Rank getters are 1-based for Stencyl users. With skip = 0, rank 1 is the
	 * first score returned by Newgrounds.
	 */
	public static function fetchLeaderboard(boardID:Int, limit:Int = 10, periodCode:String = "A", skip:Int = 0):Void
	{
		if (NG.core == null)
		{
			failLeaderboard("NG core not initialized.");
			return;
		}

		if (limit < 1)
		{
			limit = 1;
		}

		if (skip < 0)
		{
			skip = 0;
		}

		var normalizedPeriod:String = normalizeLeaderboardPeriod(periodCode);
		var period:Period = cast normalizedPeriod;

		leaderboardScores = [];
		leaderboardLoaded = false;
		leaderboardLoading = true;
		leaderboardError = "";
		leaderboardScoreboardName = "";
		leaderboardBoardID = boardID;
		leaderboardSkip = skip;

		trace("Loading " + limit + " leaderboard scores from board " + boardID + ".");

		NG.core.calls.scoreBoard.getScores(boardID, limit, skip, period, false, null, null)
			.addDataHandler(onLeaderboardResponse)
			.addErrorHandler(onLeaderboardHttpError)
			.send();
	}

	private static function normalizeLeaderboardPeriod(periodCode:String):String
	{
		if (periodCode == null)
		{
			return "A";
		}

		var normalized:String = periodCode.toUpperCase();

		if (normalized == "D" || normalized == "W" || normalized == "M" ||
			normalized == "Y" || normalized == "A")
		{
			return normalized;
		}

		trace("Invalid leaderboard period '" + periodCode + "'. Using all-time.");
		return "A";
	}

	private static function onLeaderboardResponse(response:Response<ScoreResult>):Void
	{
		if (response == null)
		{
			failLeaderboard("Newgrounds returned no leaderboard response.");
			return;
		}

		if (!response.success)
		{
			failLeaderboard(response.error != null
				? response.error.toString()
				: "Leaderboard request failed.");
			return;
		}

		if (response.result == null || !response.result.success)
		{
			failLeaderboard(response.result != null && response.result.error != null
				? response.result.error.toString()
				: "Newgrounds rejected the leaderboard request.");
			return;
		}

		leaderboardScores = response.result.data.scores != null
			? response.result.data.scores
			: [];

		if (response.result.data.scoreboard != null)
		{
			leaderboardScoreboardName = response.result.data.scoreboard.name;
		}

		leaderboardLoading = false;
		leaderboardLoaded = true;
		leaderboardError = "";

		trace("Loaded " + leaderboardScores.length + " leaderboard scores.");

		if (leaderboardCallback != null)
		{
			leaderboardCallback();
		}
	}

	private static function onLeaderboardHttpError(error:Error):Void
	{
		failLeaderboard(error != null ? error.toString() : "Leaderboard connection failed.");
	}

	private static function failLeaderboard(message:String):Void
	{
		leaderboardScores = [];
		leaderboardLoading = false;
		leaderboardLoaded = false;
		leaderboardError = message != null ? message : "Unknown leaderboard error.";

		trace("Leaderboard error: " + leaderboardError);

		if (leaderboardErrorCallback != null)
		{
			leaderboardErrorCallback();
		}
	}

	public static function setLeaderboardCallback(callbackFn:Void->Void):Void
	{
		leaderboardCallback = callbackFn;
	}

	public static function setLeaderboardErrorCallback(callbackFn:Void->Void):Void
	{
		leaderboardErrorCallback = callbackFn;
	}

	public static function getLeaderboardScoreCount():Int
	{
		return leaderboardScores != null ? leaderboardScores.length : 0;
	}

	public static function isLeaderboardLoaded():Bool
	{
		return leaderboardLoaded;
	}

	public static function isLeaderboardLoading():Bool
	{
		return leaderboardLoading;
	}

	public static function getLeaderboardError():String
	{
		return leaderboardError;
	}

	public static function getLeaderboardScoreboardName():String
	{
		return leaderboardScoreboardName;
	}

	/**
	 * Returns a property from a fetched score. Rank is 1-based.
	 */
	public static function getLeaderboardScoreProperty(property:String, rank:Int):Dynamic
	{
		var index:Int = rank - 1;

		if (leaderboardScores == null || index < 0 || index >= leaderboardScores.length)
		{
			trace("Leaderboard rank " + rank + " is outside the loaded score range.");
			return defaultLeaderboardProperty(property);
		}

		var score:Score = leaderboardScores[index];

		if (property == "rank")
		{
			return leaderboardSkip + index + 1;
		}
		else if (property == "username")
		{
			if (score.user != null)
			{
				return score.user.name;
			}

			return getUsername() != null ? getUsername() : "";
		}
		else if (property == "value")
		{
			return score.value;
		}
		else if (property == "formatted")
		{
			return score.formattedValue != null ? score.formattedValue : Std.string(score.value);
		}
		else if (property == "tag")
		{
			return score.tag != null ? score.tag : "";
		}

		trace("Invalid leaderboard score property: " + property);
		return null;
	}

	private static function defaultLeaderboardProperty(property:String):Dynamic
	{
		if (property == "rank" || property == "value")
		{
			return 0;
		}

		return "";
	}
	/**
	 * Logs a custom event to Newgrounds.
	 * The event name must be configured in the game's Newgrounds Referrals & Events settings.
	 */
	public static function logEvent(eventName:String):Void
	{
		if (NG.core == null)
		{
			trace("NG core has not been started.");
			return;
		}

		if (eventName == null || eventName == "")
		{
			trace("Newgrounds event name cannot be empty.");
			return;
		}

		trace("Logging Newgrounds event: " + eventName);

		NG.core.calls.event.logEvent(eventName)
			.addSuccessHandler(function():Void
			{
				trace("Newgrounds event logged: " + eventName);
			})
			.addErrorHandler(function(error:Error):Void
			{
				trace("Failed to log Newgrounds event: " + eventName);
				if (error != null)
				{
					trace(error.message);
				}
			})
			.send();
	}

}
