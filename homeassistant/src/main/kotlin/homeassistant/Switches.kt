package homeassistant

fun toggleSwitchDevice(
    deviceId: String,
    entityId: String,
): Action =
    SwitchDeviceAction(
        type = "toggle",
        deviceId = deviceId,
        entityId = entityId,
    )
