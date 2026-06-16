package homeassistant

fun notifyMikesPhone(message: String) = sendNotification("449719a7d011795e08e37c0f114f4771", message)

fun sendNotification(
    deviceId: String,
    message: String,
): Action =
    ServiceAction(
        action = "notify.send_message",
        target = DeviceTarget(deviceId),
        data = yamlObject("message" to message),
    )
