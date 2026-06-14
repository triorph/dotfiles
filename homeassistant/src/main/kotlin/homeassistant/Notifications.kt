package homeassistant

fun sendNotification(
    deviceId: String,
    message: String,
): Action =
    ServiceAction(
        action = "notify.send_message",
        target = deviceTarget(deviceId),
        data = yamlObject("message" to message),
    )
