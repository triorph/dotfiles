package homeassistant

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

fun turnOnLightWithRgbColour(
    entityId: String,
    rgbColour: String,
): Action =
    lightAction(
        action = "light.turn_on",
        target = EntityTarget(entityId),
        data = yamlObject("rgb_color" to rgbColour),
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
