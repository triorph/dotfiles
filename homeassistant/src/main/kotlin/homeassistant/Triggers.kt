package homeassistant

fun timeTrigger(at: String): Trigger = TimeTrigger(at = at)

fun stateTrigger(entityId: String): Trigger = StateTrigger(entityId = entityId)

fun washingMachineCurrentAboveThresholdTrigger(

) = GenericTrigger(
        mapOf(
            "trigger" to "numeric_state",
            "entity_id" to "sensor.tz3210_cehuw1lw_ts011f_current",
            "for" to Duration(minutes=20),
            "above" to 1
        )
    )

fun washingMachineCurrentBelowThresholdTrigger() = GenericTrigger(
        mapOf(
            "trigger" to "numeric_state",
            "entity_id" to "sensor.tz3210_cehuw1lw_ts011f_current",
            "for" to Duration(minutes=10),
            "below" to 1
        )
    )

fun sunsetTrigger() = GenericTrigger(mapOf("trigger" to "sun", "event" to "sunset", "offset" to 0))

fun temperatureCrossedThresholdTrigger(
    target: Target,
    threshold: AboveThreshold,
    duration: Duration? = null,
    behavior: String = "each",
): Trigger =
    TemperatureCrossedThresholdTrigger(
        target = target,
        options =
            TemperatureThresholdOptions(
                behavior = behavior,
                threshold = threshold,
                duration = duration,
            ),
    )

fun duration(
    hours: Int = 0,
    minutes: Int = 0,
    seconds: Int = 0,
): Duration = Duration(hours = hours, minutes = minutes, seconds = seconds)

fun entityTarget(entityId: String): Target = EntityTarget(entityId = entityId)

fun areaTarget(areaId: String): Target = AreaTarget(areaId = areaId)

fun deviceTarget(deviceId: String): Target = DeviceTarget(deviceId = deviceId)

fun aboveNumberThreshold(
    number: Int,
    unitOfMeasurement: String? = null,
): AboveThreshold =
    AboveThreshold(
        NumberThresholdValue(
            number = number,
            unitOfMeasurement = unitOfMeasurement,
        ),
    )

fun aboveEntityThreshold(entityId: String): AboveThreshold = AboveThreshold(EntityThresholdValue(entity = entityId))
