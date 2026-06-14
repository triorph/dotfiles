package homeassistant

fun turnOffLights(vararg entityIds: String): YamlObject =
    lightAction(
        action = "light.turn_off",
        target = entityTarget(*entityIds),
    )

fun turnOnLights(vararg entityIds: String): YamlObject =
    lightAction(
        action = "light.turn_on",
        target = entityTarget(*entityIds),
    )

fun toggleLight(entityId: String): YamlObject =
    lightAction(
        action = "light.toggle",
        target = entityTarget(entityId),
    )

fun adjustLightBrightness(
    entityId: String,
    brightnessStepPct: Int,
    continueOnError: Boolean = false,
): YamlObject =
    lightAction(
        action = "light.turn_on",
        target = entityTarget(entityId),
        data = yamlObject("brightness_step_pct" to brightnessStepPct),
        continueOnError = continueOnError,
    )

fun turnOnLightWithRgbColour(
    entityId: String,
    rgbColour: String,
): YamlObject =
    lightAction(
        action = "light.turn_on",
        target = entityTarget(entityId),
        data = yamlObject("rgb_color" to rgbColour),
    )

fun lightTurnedOnTrigger(entityId: String): YamlObject =
    yamlObject(
        "trigger" to "light.turned_on",
        "target" to entityTarget(entityId),
    )

fun lightIsOn(entityId: String): YamlObject =
    yamlObject(
        "condition" to "light.is_on",
        "target" to entityTarget(entityId),
    )

fun lightDeviceIsOn(
    deviceId: String,
    entityId: String,
    duration: YamlObject? = null,
): YamlObject =
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
): YamlObject =
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
): YamlObject =
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
    }

private fun lightAction(
    action: String,
    target: YamlObject,
    data: YamlObject = yamlObject(),
    continueOnError: Boolean = false,
): YamlObject =
    yamlObject(
        "action" to action,
        "metadata" to yamlObject(),
        "target" to target,
        "data" to data,
    ).apply {
        if (continueOnError) {
            this["continue_on_error"] = true
        }
    }

private fun entityTarget(vararg entityIds: String): YamlObject =
    yamlObject(
        "entity_id" to
            if (entityIds.size == 1) {
                entityIds.single()
            } else {
                yamlList(*entityIds)
            },
    )
