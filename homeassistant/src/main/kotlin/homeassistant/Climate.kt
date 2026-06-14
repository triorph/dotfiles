package homeassistant

private const val OFFICE_HEATPUMP_DEVICE_ID = "568bf49c8bc0b3639c29221d9a96bae0"
private const val OFFICE_HEATPUMP_HVAC_MODE_ENTITY_ID = "4882560e0c73d5d1205927e49ea5f11e"
private const val OFFICE_HEATPUMP_ENTITY_ID = "climate.mike_s_office_heatpump_mike_s_office_mike_s_office_heater"

fun officeHeatpumpIsNotOff(): Condition =
    notCondition(
        ClimateDeviceHvacModeCondition(
            deviceId = OFFICE_HEATPUMP_DEVICE_ID,
            entityId = OFFICE_HEATPUMP_HVAC_MODE_ENTITY_ID,
            hvacMode = "off",
        ),
    )

fun turnOffOfficeHeatpumpDevice(): Action =
    ServiceAction(
        action = "climate.turn_off",
        target = DeviceTarget(OFFICE_HEATPUMP_DEVICE_ID),
    )

fun officeHeatpumpIsHeating(): Condition =
    ClimateHvacModeCondition(
        target = EntityTarget(OFFICE_HEATPUMP_ENTITY_ID),
        options = yamlObject("behavior" to "any", "hvac_mode" to yamlList("heat")),
    )

fun turnOffOfficeHeatpumpEntity(): Action =
    ServiceAction(
        action = "climate.turn_off",
        target = EntityTarget(OFFICE_HEATPUMP_ENTITY_ID),
    )

fun turnOnOfficeHeatpumpEntity(): Action =
    ServiceAction(
        action = "climate.turn_on",
        target = EntityTarget(OFFICE_HEATPUMP_ENTITY_ID),
    )
