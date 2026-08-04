package io.newgrounds.crypto;

import haxe.crypto.Base64;
import haxe.io.Bytes;

/**
 * Creates the AES-128/Base64 encryption handler expected by current Newgrounds.io projects.
 * The Newgrounds encryption key is supplied as Base64 and must decode to 16 bytes.
 */
class AesEncryption
{
	public static function create(encryptionKey:String):String->String
	{
		var keyBytes:Bytes = Base64.decode(encryptionKey);

		if (keyBytes == null || keyBytes.length != 16)
		{
			throw "Newgrounds AES-128 encryption key must decode to exactly 16 bytes.";
		}

		var aes:Aes = new Aes(keyBytes);

		return function(data:String):String
		{
			return Base64.encode(aes.encrypt(Bytes.ofString(data)));
		};
	}
}
