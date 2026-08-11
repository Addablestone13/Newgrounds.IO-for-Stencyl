package io.newgrounds.objects;

@:noCompletion
typedef RawSaveSlotData = {
	id:Int,
	datetime:String,
	timestamp:Int,
	size:Int,
	url:String
}

@:forward
abstract SaveSlot(RawSaveSlotData) from RawSaveSlotData {
	public var id(get, never):Int;
	inline function get_id() return this.id;

	public var datetime(get, never):String;
	inline function get_datetime() return this.datetime;

	public var timestamp(get, never):Int;
	inline function get_timestamp() return this.timestamp;

	public var size(get, never):Int;
	inline function get_size() return this.size;

	public var url(get, never):String;
	inline function get_url() return this.url;
}
