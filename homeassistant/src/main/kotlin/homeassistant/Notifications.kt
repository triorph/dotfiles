package homeassistant

fun sendNotification(
    deviceId: String,
    message: String,
): Action =
    ServiceAction(
        action = "notify.send_message",
        target = DeviceTarget(deviceId),
        data = yamlObject("message" to message),
    )
