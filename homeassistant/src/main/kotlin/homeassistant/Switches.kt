package homeassistant

fun toggleSwitchDevice(
    deviceId: String,
    entityId: String,
): Action =
    GenericAction(
        yamlObject(
            "type" to "toggle",
            "device_id" to deviceId,
            "entity_id" to entityId,
            "domain" to "switch",
        ),
    )
