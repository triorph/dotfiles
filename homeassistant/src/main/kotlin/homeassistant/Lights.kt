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
        target = lightEntityTarget(entityId),
    )

fun adjustLightBrightness(
    entityId: String,
    brightnessStepPct: Int,
    continueOnError: Boolean = false,
): Action =
    lightAction(
        action = "light.turn_on",
        target = lightEntityTarget(entityId),
        data = yamlObject("brightness_step_pct" to brightnessStepPct),
        continueOnError = continueOnError,
    )

fun turnOnLightWithRgbColour(
    entityId: String,
    rgbColour: String,
): Action =
    lightAction(
        action = "light.turn_on",
        target = lightEntityTarget(entityId),
        data = yamlObject("rgb_color" to rgbColour),
    )

fun lightTurnedOnTrigger(entityId: String): Trigger = LightTurnedOnTrigger(target = lightEntityTarget(entityId))

fun lightIsOn(entityId: String): Condition = LightIsOnCondition(target = lightEntityTarget(entityId))

fun lightDeviceIsOn(
    deviceId: String,
    entityId: String,
    duration: YamlObject? = null,
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
    duration: YamlObject? = null,
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
    duration: YamlObject? = null,
): Condition =
    GenericCondition(
        yamlObject(
            "condition" to "device",
            "type" to type,
            "device_id" to deviceId,
            "entity_id" to entityId,
            "domain" to "light",
        ).apply {
            if (duration != null) {
                this["for"] = duration
            }
        },
    )

private fun lightAction(
    action: String,
    target: YamlObject,
    data: YamlObject = yamlObject(),
    continueOnError: Boolean = false,
): Action =
    LightAction(
        action = action,
        target = target,
        data = data,
        continueOnError = continueOnError.takeIf { it },
    )

private fun lightEntityTarget(vararg entityIds: String): YamlObject =
    yamlObject(
        "entity_id" to
            if (entityIds.size == 1) {
                entityIds.single()
            } else {
                yamlList(*entityIds)
            },
    )
