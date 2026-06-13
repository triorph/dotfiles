package homeassistant

private val colourCycle = yamlList(
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

private const val nextColourRgbTemplate = "{% set idx = states('input_number.downstairs_light_colour_index') | int + 1 %} {% set idx = idx % colour_cycle | length %} {% set colour = colour_cycle[idx] %} [{{colour[0]-}}, {{colour[1]-}}, {{colour[2]-}}]\n"
private const val nextColourIndexTemplate = "{% set idx = states('input_number.downstairs_light_colour_index') | int + 1 %} {% set idx = idx % colour_cycle | length %} {{ idx }}\n"

fun automations(): List<YamlObject> = yamlObjects(
    yamlObject(
        "definitions" to null,
        "colour_cycle" to colourCycle,
        "actions" to yamlList(
            turnOnCurrentColour(),
            advanceDownstairsColourIndex()
        ),
        "button_triggers" to yamlList(
            zhaButtonTrigger("toggle"),
            zhaButtonTrigger("on"),
            zhaButtonTrigger("off")
        ),
        "id" to "4238829e5a684e7fa4a1791dee2caf6b"
    ),
    yamlObject(
        "id" to "1780894997877",
        "alias" to "Turn off office heatpump",
        "description" to "",
        "triggers" to yamlList(
            yamlObject(
                "trigger" to "time",
                "at" to "17:00:00"
            )
        ),
        "conditions" to yamlList(
            yamlObject(
                "condition" to "or",
                "conditions" to yamlList(
                    yamlObject(
                        "condition" to "not",
                        "conditions" to yamlList(
                            yamlObject(
                                "condition" to "device",
                                "device_id" to "568bf49c8bc0b3639c29221d9a96bae0",
                                "domain" to "climate",
                                "entity_id" to "4882560e0c73d5d1205927e49ea5f11e",
                                "type" to "is_hvac_mode",
                                "hvac_mode" to "off"
                            )
                        )
                    )
                )
            )
        ),
        "actions" to yamlList(
            yamlObject(
                "action" to "climate.turn_off",
                "metadata" to yamlObject(),
                "target" to yamlObject(
                    "device_id" to "568bf49c8bc0b3639c29221d9a96bae0"
                ),
                "data" to yamlObject()
            )
        ),
        "mode" to "single"
    ),
    yamlObject(
        "id" to "1780963707995",
        "alias" to "Stair lights off",
        "description" to "",
        "triggers" to yamlList(
            yamlObject(
                "device_id" to "4a713f5c3c61ea99233c62a0c9928ece",
                "domain" to "zha",
                "type" to "remote_button_short_press",
                "subtype" to "button",
                "trigger" to "device"
            ),
            zhaButtonTrigger("toggle")
        ),
        "conditions" to yamlList(
            yamlObject(
                "condition" to "device",
                "type" to "is_on",
                "device_id" to "2c0f04abd6148843b1756b944ea925d7",
                "entity_id" to "c76155248c42d7a29d57b0938dbd49de",
                "domain" to "light",
                "for" to yamlObject(
                    "hours" to 0,
                    "minutes" to 0,
                    "seconds" to 1
                )
            )
        ),
        "actions" to yamlList(
            yamlObject(
                "action" to "light.turn_off",
                "metadata" to yamlObject(),
                "target" to yamlObject(
                    "entity_id" to yamlList(
                        "light.stair_light_1",
                        "light.stair_light_2",
                        "light.dining_room_lamp"
                    )
                ),
                "data" to yamlObject()
            )
        ),
        "mode" to "single"
    ),
    yamlObject(
        "id" to "1780963899292",
        "alias" to "Decrease lamp brightness",
        "description" to "",
        "triggers" to yamlList(
            yamlObject(
                "device_id" to "4a713f5c3c61ea99233c62a0c9928ece",
                "domain" to "zha",
                "type" to "device_rotated",
                "subtype" to "left",
                "trigger" to "device"
            )
        ),
        "conditions" to yamlList(),
        "actions" to yamlList(
            yamlObject(
                "action" to "light.turn_on",
                "metadata" to yamlObject(),
                "data" to yamlObject(
                    "brightness_step_pct" to -20
                ),
                "target" to yamlObject(
                    "entity_id" to "light.dining_room_lamp"
                )
            )
        ),
        "mode" to "single"
    ),
    yamlObject(
        "id" to "1780964087146",
        "alias" to "Increase lamp brightness",
        "description" to "",
        "triggers" to yamlList(
            yamlObject(
                "device_id" to "4a713f5c3c61ea99233c62a0c9928ece",
                "domain" to "zha",
                "type" to "device_rotated",
                "subtype" to "right",
                "trigger" to "device"
            )
        ),
        "conditions" to yamlList(),
        "actions" to yamlList(
            yamlObject(
                "action" to "light.turn_on",
                "metadata" to yamlObject(),
                "target" to yamlObject(
                    "entity_id" to "light.stair_light_1"
                ),
                "data" to yamlObject(
                    "brightness_step_pct" to 50
                ),
                "continue_on_error" to true
            ),
            yamlObject(
                "action" to "light.turn_on",
                "metadata" to yamlObject(),
                "target" to yamlObject(
                    "entity_id" to "light.stair_light_2"
                ),
                "data" to yamlObject(
                    "brightness_step_pct" to 50
                ),
                "continue_on_error" to true
            ),
            yamlObject(
                "action" to "light.turn_on",
                "metadata" to yamlObject(),
                "target" to yamlObject(
                    "entity_id" to "light.dining_room_lamp"
                ),
                "data" to yamlObject(
                    "brightness_step_pct" to 20
                )
            )
        ),
        "mode" to "single"
    ),
    yamlObject(
        "id" to "1780965369367",
        "alias" to "Toggle mike lamplight",
        "description" to "",
        "triggers" to yamlList(
            yamlObject(
                "trigger" to "event",
                "event_type" to "zha_event",
                "event_data" to yamlObject(
                    "device_ieee" to "a4:c1:38:ab:c9:62:1d:b1",
                    "device_id" to "2fd11b2eac90c1daa1d41a596dd4a57a",
                    "unique_id" to "a4:c1:38:ab:c9:62:1d:b1:1:0x0006",
                    "endpoint_id" to 1,
                    "cluster_id" to 6,
                    "command" to "toggle",
                    "args" to yamlList(),
                    "params" to yamlObject()
                )
            )
        ),
        "conditions" to yamlList(),
        "actions" to yamlList(
            yamlObject(
                "type" to "toggle",
                "device_id" to "9f60192a08622db8c597cea034d075b1",
                "entity_id" to "d3075c2bb97112a2bd9cdc4bd388ba7a",
                "domain" to "switch"
            )
        ),
        "mode" to "single"
    ),
    yamlObject(
        "id" to "1780973542501",
        "alias" to "Lights follow power off",
        "description" to "",
        "triggers" to yamlList(
            yamlObject(
                "device_id" to "2c0f04abd6148843b1756b944ea925d7",
                "domain" to "zha",
                "type" to "device_offline",
                "subtype" to "device_offline",
                "trigger" to "device"
            )
        ),
        "conditions" to yamlList(),
        "actions" to yamlList(
            yamlObject(
                "action" to "light.turn_off",
                "metadata" to yamlObject(),
                "target" to yamlObject(
                    "entity_id" to yamlList(
                        "light.smartlight_4"
                    )
                ),
                "data" to yamlObject()
            )
        ),
        "mode" to "single"
    ),
    yamlObject(
        "id" to "1780975857816",
        "alias" to "Stairs lights on",
        "description" to "",
        "triggers" to yamlList(
            yamlObject(
                "device_id" to "4a713f5c3c61ea99233c62a0c9928ece",
                "domain" to "zha",
                "type" to "remote_button_short_press",
                "subtype" to "button",
                "trigger" to "device"
            ),
            zhaButtonTrigger("toggle")
        ),
        "conditions" to yamlList(
            yamlObject(
                "condition" to "device",
                "type" to "is_off",
                "device_id" to "2c0f04abd6148843b1756b944ea925d7",
                "entity_id" to "c76155248c42d7a29d57b0938dbd49de",
                "domain" to "light",
                "for" to yamlObject(
                    "hours" to 0,
                    "minutes" to 0,
                    "seconds" to 1
                )
            )
        ),
        "actions" to yamlList(
            yamlObject(
                "action" to "light.turn_on",
                "metadata" to yamlObject(),
                "target" to yamlObject(
                    "entity_id" to yamlList(
                        "light.stair_light_1",
                        "light.stair_light_2",
                        "light.dining_room_lamp"
                    )
                ),
                "data" to yamlObject()
            )
        ),
        "mode" to "single"
    ),
    yamlObject(
        "id" to "toggle_downstairs_lamp",
        "alias" to "Toggle downstairs lamp",
        "description" to "",
        "triggers" to yamlList(
            yamlObject(
                "device_id" to "4a713f5c3c61ea99233c62a0c9928ece",
                "domain" to "zha",
                "type" to "remote_button_double_press",
                "subtype" to "button_1",
                "trigger" to "device"
            ),
            zhaButtonTrigger("on")
        ),
        "conditions" to yamlList(),
        "actions" to yamlList(
            yamlObject(
                "action" to "light.toggle",
                "metadata" to yamlObject(),
                "target" to yamlObject(
                    "entity_id" to "light.dining_room_lamp"
                ),
                "data" to yamlObject()
            )
        ),
        "mode" to "single"
    ),
    yamlObject(
        "id" to "stair_light_1_lamp_colour",
        "alias" to "Set stair light 1 to new colour",
        "description" to "",
        "triggers" to yamlList(
            stateTrigger("input_number.downstairs_light_colour_index")
        ),
        "variables" to colourVariables(includeDefaultColour = true),
        "conditions" to yamlList(
            lightIsOn("light.stair_light_1")
        ),
        "actions" to yamlList(
            turnOnCurrentColour("light.stair_light_1")
        ),
        "mode" to "single"
    ),
    yamlObject(
        "id" to "stair_light_2_lamp_colour",
        "alias" to "Set stair light 2 to new colour",
        "description" to "",
        "triggers" to yamlList(
            stateTrigger("input_number.downstairs_light_colour_index")
        ),
        "variables" to colourVariables(includeDefaultColour = true),
        "conditions" to yamlList(
            lightIsOn("light.stair_light_2")
        ),
        "actions" to yamlList(
            turnOnCurrentColour("light.stair_light_2")
        ),
        "mode" to "single"
    ),
    yamlObject(
        "id" to "downstairs_lamp_colour",
        "alias" to "Set downstairs light to new colour",
        "description" to "",
        "triggers" to yamlList(
            stateTrigger("input_number.downstairs_light_colour_index")
        ),
        "variables" to colourVariables(includeDefaultColour = true),
        "conditions" to yamlList(
            lightIsOn("light.dining_room_lamp")
        ),
        "actions" to yamlList(
            turnOnCurrentColour("light.dining_room_lamp")
        ),
        "mode" to "single"
    ),
    yamlObject(
        "id" to "1780986988887",
        "alias" to "Cycle stair light colours",
        "description" to "",
        "triggers" to yamlList(
            yamlObject(
                "device_id" to "4a713f5c3c61ea99233c62a0c9928ece",
                "domain" to "zha",
                "type" to "remote_button_long_press",
                "subtype" to "button_1",
                "trigger" to "device"
            ),
            zhaButtonTrigger("off")
        ),
        "variables" to colourVariables(),
        "actions" to yamlList(
            advanceDownstairsColourIndex()
        ),
        "mode" to "single"
    ),
    yamlObject(
        "id" to "set_stair_light_1_colour_when_on",
        "alias" to "Set the stair light 1 colour when turned on",
        "description" to "",
        "triggers" to lightTurnedOnTrigger("light.stair_light_1"),
        "variables" to colourVariables(includeDefaultColour = true),
        "actions" to yamlList(
            turnOnCurrentColour("light.stair_light_1")
        )
    ),
    yamlObject(
        "id" to "set_stair_light_2_colour_when_on",
        "alias" to "Set the stair light 2 colour when turned on",
        "description" to "",
        "triggers" to lightTurnedOnTrigger("light.stair_light_2"),
        "variables" to colourVariables(includeDefaultColour = true),
        "actions" to yamlList(
            turnOnCurrentColour("light.stair_light_2")
        )
    ),
    yamlObject(
        "id" to "1781210376062",
        "alias" to "Notify heat pump can be turned off",
        "description" to "",
        "triggers" to yamlList(
            yamlObject(
                "trigger" to "temperature.crossed_threshold",
                "target" to yamlObject(
                    "entity_id" to "sensor.temperature_humidity_sensor_1_temperature"
                ),
                "options" to yamlObject(
                    "behavior" to "each",
                    "for" to yamlObject(
                        "hours" to 0,
                        "minutes" to 10,
                        "seconds" to 0
                    ),
                    "threshold" to yamlObject(
                        "type" to "above",
                        "value" to yamlObject(
                            "active_choice" to "number",
                            "number" to 18,
                            "unit_of_measurement" to "°C"
                        )
                    )
                )
            )
        ),
        "conditions" to yamlList(
            yamlObject(
                "condition" to "time",
                "after" to "09:00:00",
                "before" to "17:00:00"
            )
        ),
        "actions" to yamlList(
            yamlObject(
                "action" to "notify.send_message",
                "metadata" to yamlObject(),
                "target" to yamlObject(
                    "device_id" to "449719a7d011795e08e37c0f114f4771"
                ),
                "data" to yamlObject(
                    "message" to "Downstairs heat reached threshold "
                )
            )
        ),
        "mode" to "single"
    ),
    yamlObject(
        "id" to "1781216970827",
        "alias" to "Disable heatpump after reaching threshold",
        "description" to "",
        "triggers" to yamlList(
            yamlObject(
                "trigger" to "temperature.crossed_threshold",
                "target" to yamlObject(
                    "area_id" to "mike_s_office"
                ),
                "options" to yamlObject(
                    "behavior" to "each",
                    "threshold" to yamlObject(
                        "type" to "above",
                        "value" to yamlObject(
                            "active_choice" to "entity",
                            "entity" to "input_number.mikes_office_target_heatpump_heat_temp"
                        )
                    ),
                    "for" to yamlObject(
                        "hours" to 0,
                        "minutes" to 5,
                        "seconds" to 0
                    )
                )
            )
        ),
        "conditions" to yamlList(
            yamlObject(
                "condition" to "climate.is_hvac_mode",
                "target" to yamlObject(
                    "entity_id" to "climate.mike_s_office_heatpump_mike_s_office_mike_s_office_heater"
                ),
                "options" to yamlObject(
                    "behavior" to "any",
                    "hvac_mode" to yamlList(
                        "heat"
                    )
                )
            )
        ),
        "actions" to yamlList(
            yamlObject(
                "action" to "climate.turn_off",
                "metadata" to yamlObject(),
                "target" to yamlObject(
                    "entity_id" to "climate.mike_s_office_heatpump_mike_s_office_mike_s_office_heater"
                ),
                "data" to yamlObject()
            )
        ),
        "mode" to "single"
    )
)

private fun rgb(red: Int, green: Int, blue: Int): List<Int> =
    listOf(red, green, blue)

private fun colourVariables(includeDefaultColour: Boolean = false): YamlObject =
    if (includeDefaultColour) {
        yamlObject(
            "colour" to defaultColour,
            "colour_cycle" to colourCycle,
        )
    } else {
        yamlObject("colour_cycle" to colourCycle)
    }

private fun turnOnCurrentColour(entityId: String? = null): YamlObject =
    yamlObject(
        "action" to "light.turn_on",
        "metadata" to yamlObject(),
        "data" to yamlObject("rgb_color" to nextColourRgbTemplate),
    ).apply {
        if (entityId != null) {
            this["target"] = yamlObject("entity_id" to entityId)
        }
    }

private fun advanceDownstairsColourIndex(): YamlObject =
    yamlObject(
        "action" to "input_number.set_value",
        "entity_id" to "input_number.downstairs_light_colour_index",
        "data" to yamlObject("value" to nextColourIndexTemplate),
    )

private fun zhaButtonTrigger(command: String): YamlObject =
    yamlObject(
        "trigger" to "event",
        "event_type" to "zha_event",
        "event_data" to yamlObject(
            "device_ieee" to "a4:c1:38:7e:82:21:7d:37",
            "device_id" to "628977d0676426888a7f7c217a0710f9",
            "unique_id" to "a4:c1:38:7e:82:21:7d:37:1:0x0006",
            "endpoint_id" to 1,
            "cluster_id" to 6,
            "command" to command,
            "args" to yamlList(),
            "params" to yamlObject(),
        ),
    )

private fun stateTrigger(entityId: String): YamlObject =
    yamlObject(
        "trigger" to "state",
        "entity_id" to entityId,
    )

private fun lightTurnedOnTrigger(entityId: String): YamlObject =
    yamlObject(
        "trigger" to "light.turned_on",
        "target" to yamlObject("entity_id" to entityId),
    )

private fun lightIsOn(entityId: String): YamlObject =
    yamlObject(
        "condition" to "light.is_on",
        "target" to yamlObject("entity_id" to entityId),
    )
