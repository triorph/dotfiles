package homeassistant

fun toggleSwitchDevice(
    deviceId: String,
    entityId: String,
): YamlObject =
    yamlObject(
        "type" to "toggle",
        "device_id" to deviceId,
        "entity_id" to entityId,
        "domain" to "switch",
    )
