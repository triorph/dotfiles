package homeassistant

private data class DeviceButton(
    val deviceId: String,
    val domain: String = "zha",
)

private data class ZhaEventButton(
    val deviceIeee: String,
    val deviceId: String,
    val uniqueId: String,
    val endpointId: Int = 1,
    val clusterId: Int = 6,
)

private val ikeaShortcutButton =
    DeviceButton(deviceId = "4a713f5c3c61ea99233c62a0c9928ece")

private val downstairsPowerSensor =
    DeviceButton(deviceId = "2c0f04abd6148843b1756b944ea925d7")

private val bedroomMikeLamplightButton =
    ZhaEventButton(
        deviceIeee = "a4:c1:38:ab:c9:62:1d:b1",
        deviceId = "2fd11b2eac90c1daa1d41a596dd4a57a",
        uniqueId = "a4:c1:38:ab:c9:62:1d:b1:1:0x0006",
    )

private val downstairsButton =
    ZhaEventButton(
        deviceIeee = "a4:c1:38:7e:82:21:7d:37",
        deviceId = "628977d0676426888a7f7c217a0710f9",
        uniqueId = "a4:c1:38:7e:82:21:7d:37:1:0x0006",
    )

fun ikeaShortcutButtonShortPress(): YamlObject =
    deviceButtonTrigger(ikeaShortcutButton, type = "remote_button_short_press", subtype = "button")

fun ikeaShortcutButtonDoublePress(): YamlObject =
    deviceButtonTrigger(ikeaShortcutButton, type = "remote_button_double_press", subtype = "button_1")

fun ikeaShortcutButtonLongPress(): YamlObject =
    deviceButtonTrigger(ikeaShortcutButton, type = "remote_button_long_press", subtype = "button_1")

fun ikeaShortcutButtonRotatedLeft(): YamlObject = deviceButtonTrigger(ikeaShortcutButton, type = "device_rotated", subtype = "left")

fun ikeaShortcutButtonRotatedRight(): YamlObject = deviceButtonTrigger(ikeaShortcutButton, type = "device_rotated", subtype = "right")

fun downstairsPowerSensorOffline(): YamlObject =
    deviceButtonTrigger(downstairsPowerSensor, type = "device_offline", subtype = "device_offline")

fun bedroomMikeLamplightButtonToggle(): YamlObject = zhaEventButtonTrigger(bedroomMikeLamplightButton, command = "toggle")

fun downstairsButtonToggle(): YamlObject = zhaEventButtonTrigger(downstairsButton, command = "toggle")

fun downstairsButtonOn(): YamlObject = zhaEventButtonTrigger(downstairsButton, command = "on")

fun downstairsButtonOff(): YamlObject = zhaEventButtonTrigger(downstairsButton, command = "off")

private fun deviceButtonTrigger(
    button: DeviceButton,
    type: String,
    subtype: String,
): YamlObject =
    yamlObject(
        "device_id" to button.deviceId,
        "domain" to button.domain,
        "type" to type,
        "subtype" to subtype,
        "trigger" to "device",
    )

private fun zhaEventButtonTrigger(
    button: ZhaEventButton,
    command: String,
): YamlObject =
    yamlObject(
        "trigger" to "event",
        "event_type" to "zha_event",
        "event_data" to
            yamlObject(
                "device_ieee" to button.deviceIeee,
                "device_id" to button.deviceId,
                "unique_id" to button.uniqueId,
                "endpoint_id" to button.endpointId,
                "cluster_id" to button.clusterId,
                "command" to command,
                "args" to yamlList(),
                "params" to yamlObject(),
            ),
    )
