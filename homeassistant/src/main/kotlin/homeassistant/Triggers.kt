package homeassistant

fun timeTrigger(at: String): Trigger = TimeTrigger(at = at)

fun stateTrigger(entityId: String): Trigger = StateTrigger(entityId = entityId)

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
