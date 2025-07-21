Init with App ID: _____ Encryption Key: _____  [Debug/Release]

Use this block at the start of your game to start the API.  For the encryption settings on the Newgrounds site, choose RC4 and Base64.  Then enter the matching key in this block along with your app ID.  Use the "Debug" dropdown option when testing and the "Release" dropdown option when publishing.


Log in to Newgrounds

This block is required even for games hosted directly on Newgrounds servers. You need to use the above block, before this one is used.


Set Unlock Callback  [Medal]

This optional block is used to respond to a medal unlock.  The medal info can be used to create a popup since by default nothing is displayed when a medal is unlocked.  You can use the embedded "Medal" block with the next block to get any of the medal properties.


_____ of Medal _____

This block can be used with the previous one to get one of the medal properties.  In my testing, the point value always showed 0 and the image URL wasn't usable due to a CORS violation (blocked by Newgrounds), but I left those properties in there anyway.


Unlock Medal with ID _____

This unlocks a medal using the ID assigned to the medal by Newgrounds (not the name).  If the medal is unlocked, the medal callback will be triggered if there is one.  If "Debug" was selected when starting the API, the medal will be locked so that it can be unlocked again.


Submit Score ____ to Scoreboard ID ____

Submit a score to the given scoreboard. Make sure the player is logged in.


Get Newgrounds Username

Allows for collecting the Newgrounds username of the player.


Is player signed in to Newgrounds?

Returns true if the player is logged into Newgrounds. Returns false if the player is not logged into Newgrounds.
