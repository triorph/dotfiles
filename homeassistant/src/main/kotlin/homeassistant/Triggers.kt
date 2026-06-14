package homeassistant

fun timeTrigger(at: String): Trigger = TimeTrigger(at = at)

fun stateTrigger(entityId: String): Trigger = StateTrigger(entityId = entityId)

fun temperatureCrossedThresholdTrigger(
    target: YamlObject,
    threshold: YamlObject,
    duration: YamlObject? = null,
    behavior: String = "each",
): Trigger =
    GenericTrigger(
        yamlObject(
            "trigger" to "temperature.crossed_threshold",
            "target" to target,
            "options" to
                yamlObject(
                    "behavior" to behavior,
                    "threshold" to threshold,
                ).apply {
                    if (duration != null) {
                        this["for"] = duration
                    }
                },
        ),
    )

fun duration(
    hours: Int = 0,
    minutes: Int = 0,
    seconds: Int = 0,
): YamlObject =
    yamlObject(
        "hours" to hours,
        "minutes" to minutes,
        "seconds" to seconds,
    )

fun entityTarget(entityId: String): YamlObject = yamlObject("entity_id" to entityId)

fun areaTarget(areaId: String): YamlObject = yamlObject("area_id" to areaId)

fun deviceTarget(deviceId: String): YamlObject = yamlObject("device_id" to deviceId)

fun aboveNumberThreshold(
    number: Int,
    unitOfMeasurement: String? = null,
): YamlObject =
    aboveThreshold(
        yamlObject(
            "active_choice" to "number",
            "number" to number,
        ).apply {
            if (unitOfMeasurement != null) {
                this["unit_of_measurement"] = unitOfMeasurement
            }
        },
    )

fun aboveEntityThreshold(entityId: String): YamlObject =
    aboveThreshold(
        yamlObject(
            "active_choice" to "entity",
            "entity" to entityId,
        ),
    )

private fun aboveThreshold(value: YamlObject): YamlObject =
    yamlObject(
        "type" to "above",
        "value" to value,
    )
