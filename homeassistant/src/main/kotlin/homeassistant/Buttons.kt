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

private val downstairsDial =
    ZhaEventButton(
        deviceIeee = "a4:c1:38:e3:14:42:b8:7a",
        deviceId = "4a713f5c3c61ea99233c62a0c9928ece",
        uniqueId = "a4:c1:38:e3:14:42:b8:7a:1:0x0006",
    )

private val downstairsPowerSensor = DeviceButton(deviceId = "2c0f04abd6148843b1756b944ea925d7")

private val officeDial =
    ZhaEventButton(
        deviceIeee = "a4:c1:38:a6:32:e2:44:b5",
        deviceId = "16447bd2ede6b4941627e3bc14f58c13",
        uniqueId = "a4:c1:38:a6:32:e2:44:b5:1:0x0006",
    )

private val bedroomMikeLamplightButton =
    ZhaEventButton(
        deviceIeee = "a4:c1:38:ab:c9:62:1d:b1",
        deviceId = "2fd11b2eac90c1daa1d41a596dd4a57a",
        uniqueId = "a4:c1:38:ab:c9:62:1d:b1:1:0x0006",
    )

private val upstairsButton =
    ZhaEventButton(
        deviceIeee = "a4:c1:38:7e:82:21:7d:37",
        deviceId = "628977d0676426888a7f7c217a0710f9",
        uniqueId = "a4:c1:38:7e:82:21:7d:37:1:0x0006",
    )

fun downstairsDialClick(): Trigger =
    zhaEventButtonTrigger(downstairsDial, command = "remote_button_short_press")

fun downstairsDialDoubleClick(): Trigger =
    zhaEventButtonTrigger(downstairsDial, command = "remote_button_double_press")

fun downstairsDialHold(): Trigger =
    zhaEventButtonTrigger(downstairsDial, command = "remote_button_long_press")

fun downstairsDialTurnLeft(): Trigger = zhaEventButtonTrigger(downstairsDial, command = "left")

fun downstairsDialTurnRight(): Trigger = zhaEventButtonTrigger(downstairsDial, command = "right")

fun downstairsPowerSensorOffline(): Trigger =
    deviceButtonTrigger(downstairsPowerSensor, type = "device_offline", subtype = "device_offline")

fun officeDialClick(): Trigger =
    zhaEventButtonTrigger(officeDial, command = "remote_button_short_press")

fun officeDialDoubleClick(): Trigger =
    zhaEventButtonTrigger(officeDial, command = "remote_button_double_press")

fun bedroomButtonClick(): Trigger = zhaEventButtonTrigger(bedroomMikeLamplightButton, command = "toggle")
fun bedroomButtonDoubleClick(): Trigger = zhaEventButtonTrigger(bedroomMikeLamplightButton, command = "on")

fun upstairsButtonClick(): Trigger = zhaEventButtonTrigger(upstairsButton, command = "toggle")
fun upstairsButtonDoubleClick(): Trigger = zhaEventButtonTrigger(upstairsButton, command = "on")
fun upstairsButtonHold(): Trigger = zhaEventButtonTrigger(upstairsButton, command = "off")

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
