package homeassistant

fun sendNotification(
    deviceId: String,
    message: String,
): YamlObject =
    yamlObject(
        "action" to "notify.send_message",
        "metadata" to yamlObject(),
        "target" to deviceTarget(deviceId),
        "data" to yamlObject("message" to message),
    )
