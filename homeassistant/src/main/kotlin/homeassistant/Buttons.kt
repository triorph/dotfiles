package homeassistant

private data class ZigbeeMqttActionButton(
    val deviceId: String,
)

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
    ZigbeeMqttActionButton("downstairs_dial")

private val officeDial =
    ZigbeeMqttActionButton("mikes_office_dial")

private val bedroomMikeLamplightButton =
    ZigbeeMqttActionButton("mikes_bedside_button")

private val upstairsButton =
    ZigbeeMqttActionButton("upstairs_button")

fun downstairsDialClick(): Trigger = zigbeeMqttActionButtonTrigger(downstairsDial, action = "single")

fun downstairsDialDoubleClick(): Trigger = zigbeeMqttActionButtonTrigger(downstairsDial, action = "double")

fun downstairsDialHold(): Trigger = zigbeeMqttActionButtonTrigger(downstairsDial, action = "hold")

fun downstairsDialTurnLeft(): Trigger = zigbeeMqttActionButtonTrigger(downstairsDial, action = "rotate_left")

fun downstairsDialTurnRight(): Trigger = zigbeeMqttActionButtonTrigger(downstairsDial, action = "rotate_right")

fun officeDialClick(): Trigger = zigbeeMqttActionButtonTrigger(officeDial, action = "single")

fun officeDialDoubleClick(): Trigger = zigbeeMqttActionButtonTrigger(officeDial, action = "double")

fun bedroomButtonClick(): Trigger = zigbeeMqttActionButtonTrigger(bedroomMikeLamplightButton, action = "single")

fun bedroomButtonDoubleClick(): Trigger = zigbeeMqttActionButtonTrigger(bedroomMikeLamplightButton, action = "double")

fun upstairsButtonClick(): Trigger = zigbeeMqttActionButtonTrigger(upstairsButton, action = "single")

fun upstairsButtonDoubleClick(): Trigger = zigbeeMqttActionButtonTrigger(upstairsButton, action = "double")

fun upstairsButtonHold(): Trigger = zigbeeMqttActionButtonTrigger(upstairsButton, action = "hold")

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

private fun zigbeeMqttActionButtonTrigger(
    button: ZigbeeMqttActionButton,
    action: String,
): Trigger =
    ZigbeeMqttTrigger(
        options =
            ZigbeeMqttOptions(
                payload = action,
                topic = "zigbee2mqtt/${button.deviceId}/action",
            ),
    )
