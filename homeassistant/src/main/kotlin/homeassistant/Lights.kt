package homeassistant

fun toggleMikeLamp(): Action =
    toggleSwitchDevice(
        deviceId = "9f60192a08622db8c597cea034d075b1",
        entityId = "d3075c2bb97112a2bd9cdc4bd388ba7a",
    )

fun turnOffLights(vararg entityIds: String): Action =
    lightAction(
        action = "light.turn_off",
        target = lightEntityTarget(*entityIds),
    )

fun turnOnLights(vararg entityIds: String): Action =
    lightAction(
        action = "light.turn_on",
        target = lightEntityTarget(*entityIds),
    )

fun toggleLight(entityId: String): Action =
    lightAction(
        action = "light.toggle",
        target = EntityTarget(entityId),
    )

fun adjustLightBrightness(
    entityId: String,
    brightnessStepPct: Int,
    continueOnError: Boolean = false,
): Action =
    lightAction(
        action = "light.turn_on",
        target = EntityTarget(entityId),
        data = yamlObject("brightness_step_pct" to brightnessStepPct),
        continueOnError = continueOnError,
    )

fun turnOnLightWithRgbColour(entityId: String): Action =
    lightAction(
        action = "light.turn_on",
        target = EntityTarget(entityId),
        data = yamlObject("rgb_color" to NEXT_COLOUR_RGB_TEMPLATE),
    )

fun lightTurnedOnTrigger(entityId: String): Trigger = LightTurnedOnTrigger(target = EntityTarget(entityId))

fun lightIsOn(entityId: String): Condition = LightIsOnCondition(target = EntityTarget(entityId))

fun lightDeviceIsOn(
    deviceId: String,
    entityId: String,
    duration: Duration? = null,
): Condition =
    lightDeviceStateCondition(
        type = "is_on",
        deviceId = deviceId,
        entityId = entityId,
        duration = duration,
    )

fun lightDeviceIsOff(
    deviceId: String,
    entityId: String,
    duration: Duration? = null,
): Condition =
    lightDeviceStateCondition(
        type = "is_off",
        deviceId = deviceId,
        entityId = entityId,
        duration = duration,
    )

private fun lightDeviceStateCondition(
    type: String,
    deviceId: String,
    entityId: String,
    duration: Duration? = null,
): Condition =
    DeviceCondition(
        type = type,
        deviceId = deviceId,
        entityId = entityId,
        domain = "light",
        duration = duration,
    )

private fun lightAction(
    action: String,
    target: Target,
    data: YamlObject = yamlObject(),
    continueOnError: Boolean = false,
): Action =
    LightAction(
        action = action,
        target = target,
        data = data,
        continueOnError = continueOnError.takeIf { it },
    )

private fun lightEntityTarget(vararg entityIds: String): Target =
    if (entityIds.size == 1) {
        EntityTarget(entityIds.single())
    } else {
        GenericTarget(yamlObject("entity_id" to yamlList(*entityIds)))
    }

fun colourVariables(includeDefaultColour: Boolean = false): Map<String, Any?> =
    if (includeDefaultColour) {
        yamlObject(
            "colour" to defaultColour,
            "colour_cycle" to colourCycle,
        )
    } else {
        yamlObject("colour_cycle" to colourCycle)
    }

private val colourCycle =
    yamlList(
        rgb(255, 137, 14),
        rgb(255, 193, 142),
        rgb(255, 229, 207),
        rgb(255, 255, 251),
        rgb(255, 112, 86),
        rgb(112, 255, 86),
        rgb(129, 173, 255),
        rgb(215, 151, 255),
        rgb(255, 159, 242),
    )

private val defaultColour = rgb(255, 0, 0)

private fun rgb(
    red: Int,
    green: Int,
    blue: Int,
): List<Int> = listOf(red, green, blue)

private const val NEXT_COLOUR_RGB_TEMPLATE =
    "{% set idx = states('input_number.downstairs_light_colour_index') | int + 1 %} {% set idx = idx % colour_cycle | length %} {% set colour = colour_cycle[idx] %} [{{colour[0]-}}, {{colour[1]-}}, {{colour[2]-}}]\n"
private const val NEXT_COLOUR_INDEX_TEMPLATE =
    "{% set idx = states('input_number.downstairs_light_colour_index') | int + 1 %} {% set idx = idx % colour_cycle | length %} {{ idx }}\n"

fun advanceDownstairsColourIndex(): Action =
    setInputNumberValue(
        entityId = "input_number.downstairs_light_colour_index",
        value = NEXT_COLOUR_INDEX_TEMPLATE,
    )
