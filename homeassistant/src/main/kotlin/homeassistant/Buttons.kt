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

private val ikeaShortcutButton = DeviceButton(deviceId = "4a713f5c3c61ea99233c62a0c9928ece")

private val downstairsPowerSensor = DeviceButton(deviceId = "2c0f04abd6148843b1756b944ea925d7")

private val buttonWithDial2 = DeviceButton(deviceId = "16447bd2ede6b4941627e3bc14f58c13")

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

fun ikeaShortcutButtonShortPress(): Trigger =
    deviceButtonTrigger(ikeaShortcutButton, type = "remote_button_short_press", subtype = "button")

fun ikeaShortcutButtonDoublePress(): Trigger =
    deviceButtonTrigger(ikeaShortcutButton, type = "remote_button_double_press", subtype = "button_1")

fun ikeaShortcutButtonLongPress(): Trigger =
    deviceButtonTrigger(ikeaShortcutButton, type = "remote_button_long_press", subtype = "button_1")

fun ikeaShortcutButtonRotatedLeft(): Trigger = deviceButtonTrigger(ikeaShortcutButton, type = "device_rotated", subtype = "left")

fun ikeaShortcutButtonRotatedRight(): Trigger = deviceButtonTrigger(ikeaShortcutButton, type = "device_rotated", subtype = "right")

fun downstairsPowerSensorOffline(): Trigger =
    deviceButtonTrigger(downstairsPowerSensor, type = "device_offline", subtype = "device_offline")

fun buttonWithDial2SingleClick(): Trigger = deviceButtonTrigger(buttonWithDial2, type = "remote_button_short_press", subtype = "button")

fun buttonWithDial2DoubleClick(): Trigger = deviceButtonTrigger(buttonWithDial2, type = "remote_button_double_press", subtype = "button_1")

fun bedroomMikeLamplightButtonToggle(): Trigger = zhaEventButtonTrigger(bedroomMikeLamplightButton, command = "toggle")

fun downstairsButtonToggle(): Trigger = zhaEventButtonTrigger(downstairsButton, command = "toggle")

fun downstairsButtonOn(): Trigger = zhaEventButtonTrigger(downstairsButton, command = "on")

fun downstairsButtonOff(): Trigger = zhaEventButtonTrigger(downstairsButton, command = "off")

private fun deviceButtonTrigger(
    button: DeviceButton,
    type: String,
    subtype: String,
): Trigger =
    DeviceTrigger(
        deviceId = button.deviceId,
        domain = button.domain,
        type = type,
        subtype = subtype,
    )

private fun zhaEventButtonTrigger(
    button: ZhaEventButton,
    command: String,
): Trigger =
    EventTrigger(
        eventType = "zha_event",
        eventData =
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
