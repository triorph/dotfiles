package homeassistant

private const val OFFICE_HEATPUMP_DEVICE_ID = "568bf49c8bc0b3639c29221d9a96bae0"
private const val OFFICE_HEATPUMP_HVAC_MODE_ENTITY_ID = "4882560e0c73d5d1205927e49ea5f11e"
private const val OFFICE_HEATPUMP_ENTITY_ID = "climate.mike_s_office_heatpump_mike_s_office_mike_s_office_heater"

fun officeHeatpumpIsNotOff(): YamlObject =
    notCondition(
        yamlObject(
            "condition" to "device",
            "device_id" to OFFICE_HEATPUMP_DEVICE_ID,
            "domain" to "climate",
            "entity_id" to OFFICE_HEATPUMP_HVAC_MODE_ENTITY_ID,
            "type" to "is_hvac_mode",
            "hvac_mode" to "off",
        ),
    )

fun turnOffOfficeHeatpumpDevice(): YamlObject =
    yamlObject(
        "action" to "climate.turn_off",
        "metadata" to yamlObject(),
        "target" to deviceTarget(OFFICE_HEATPUMP_DEVICE_ID),
        "data" to yamlObject(),
    )

fun officeHeatpumpIsHeating(): YamlObject =
    yamlObject(
        "condition" to "climate.is_hvac_mode",
        "target" to entityTarget(OFFICE_HEATPUMP_ENTITY_ID),
        "options" to yamlObject("behavior" to "any", "hvac_mode" to yamlList("heat")),
    )

fun turnOffOfficeHeatpumpEntity(): YamlObject =
    yamlObject(
        "action" to "climate.turn_off",
        "metadata" to yamlObject(),
        "target" to entityTarget(OFFICE_HEATPUMP_ENTITY_ID),
        "data" to yamlObject(),
    )
