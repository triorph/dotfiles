package homeassistant

private const val OFFICE_HEATPUMP_ENTITY_ID = "climate.mike_s_office_heatpump_mike_s_office_mike_s_office_heater"
private const val OFFICE_HEATPUMP_SWITCH_ENTITY_ID =
    "switch.mike_s_office_heatpump_mike_s_office_mike_s_office_heat_on_off"

fun officeHeatpumpIsOn(): Condition =
    ClimateIsOnCondition(EntityTarget(OFFICE_HEATPUMP_ENTITY_ID))

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
