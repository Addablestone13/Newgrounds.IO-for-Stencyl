package io.newgrounds.components;

import io.newgrounds.objects.events.Result.CloudSaveResult;
import io.newgrounds.objects.events.Result.CloudSaveSlotsResult;
import io.newgrounds.NGLite;

class CloudSaveComponent extends Component {
	public function new(core:NGLite){ super(core); }

	public function setData(id:Int, data:String):Call<CloudSaveResult> {
		return new Call<CloudSaveResult>(_core, "CloudSave.setData", true)
			.addComponentParameter("id", id)
			.addComponentParameter("data", data);
	}

	public function loadSlot(id:Int):Call<CloudSaveResult> {
		return new Call<CloudSaveResult>(_core, "CloudSave.loadSlot", true)
			.addComponentParameter("id", id);
	}

	public function loadSlots():Call<CloudSaveSlotsResult> {
		return new Call<CloudSaveSlotsResult>(_core, "CloudSave.loadSlots", true);
	}

	public function clearSlot(id:Int):Call<CloudSaveResult> {
		return new Call<CloudSaveResult>(_core, "CloudSave.clearSlot", true)
			.addComponentParameter("id", id);
	}
}
