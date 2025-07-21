import io.newgrounds.NG;
import io.newgrounds.objects.Error;
import io.newgrounds.objects.Medal;
import io.newgrounds.objects.ScoreBoard;

class StencylNG
{
	public static var unlockCallback:Medal->Void;
	public static var debug:Bool = false;

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
		NG.core.initEncryption(encryptionKey, io.newgrounds.crypto.Cipher.RC4, io.newgrounds.crypto.EncryptionFormat.BASE_64);
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
		var medal:Medal =  NG.core.medals.get(id);
		//trace(medal.toString());

		if (medal.unlocked  && !debug)
		{
			trace("Medal is already unlocked.");
		}
		else
		{
			if (unlockCallback == null)
			{
				medal.onUnlock.add(function ():Void { trace('${medal.name} unlocked:${medal.unlocked}'); });
			}
			else
			{
				medal.onUnlock.add(function ():Void { unlockCallback(medal); });
			}
			
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
	
	public static function isUserLoggedIn():Bool {
        return NG.core != null && NG.core.loggedIn;
	}
	
	public static function isLoggedIn():Bool {
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

	public static function getUsername():String {
	if (NG.core == null) {
		trace("NG core not initialized.");
		return null;
	}

	if (!NG.core.loggedIn) {
        trace("User not logged in.");
        return null;
	}

	if (NG.core.user == null) {
        trace("User data not available.");
        return null;
	}

	return NG.core.user.name;
}


public static function submitScore(boardID:Int, score:Int) {
    if (NG.core == null) {
        trace("NG core not initialized.");
        return;
    }
    
    if (!NG.core.loggedIn) {
        trace("User not logged in.");
        return;
    }
    
    if (NG.core.scoreBoards == null) {
        trace("Scoreboards not loaded, loading now.");
        NG.core.requestScoreBoards(function() {
            submitScore(boardID, score);
        });
        return;
    }
    
    var board = NG.core.scoreBoards.get(boardID);
    if (board == null) {
        trace("Scoreboard ID " + boardID + " not found.");
        return;
    }
    
    trace("Submitting score " + score + " to board " + boardID);
    

  board.scorePostedCallback = function(response) {
    trace("Raw response: " + Std.string(response));

    if (response.success) {
        trace("Score posted successfully!");
    } else if (response.result != null && response.result.message != null) {
        trace("Failed to post score: " + response.result.message);
    } else {
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
            NG.core.requestScoreBoards(function() {
                trace("Scoreboards loaded.");
                submitScore(boardID, score);
            });
        }
    }


}
