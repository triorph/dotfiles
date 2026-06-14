package homeassistant

private val colourCycle =
    yamlList(
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

private const val NEXT_COLOUR_RGB_TEMPLATE =
    "{% set idx = states('input_number.downstairs_light_colour_index') | int + 1 %} {% set idx = idx % colour_cycle | length %} {% set colour = colour_cycle[idx] %} [{{colour[0]-}}, {{colour[1]-}}, {{colour[2]-}}]\n"
private const val NEXT_COLOUR_INDEX_TEMPLATE =
    "{% set idx = states('input_number.downstairs_light_colour_index') | int + 1 %} {% set idx = idx % colour_cycle | length %} {{ idx }}\n"

fun turnOffOfficeHeatpumpOnTimer() =
    automation(
        id = "1780894997877",
        alias = "Turn off office heatpump on timer",
    ) {
        triggers(yamlObject("trigger" to "time", "at" to "17:00:00"))
        conditions(
            yamlObject(
                "condition" to "or",
                "conditions" to
                    yamlList(
                        yamlObject(
                            "condition" to "not",
                            "conditions" to
                                yamlList(
                                    yamlObject(
                                        "condition" to
                                            "device",
                                        "device_id" to
                                            "568bf49c8bc0b3639c29221d9a96bae0",
                                        "domain" to
                                            "climate",
                                        "entity_id" to
                                            "4882560e0c73d5d1205927e49ea5f11e",
                                        "type" to
                                            "is_hvac_mode",
                                        "hvac_mode" to
                                            "off",
                                    ),
                                ),
                        ),
                    ),
            ),
        )
        actions(
            yamlObject(
                "action" to "climate.turn_off",
                "metadata" to yamlObject(),
                "target" to
                    yamlObject(
                        "device_id" to
                            "568bf49c8bc0b3639c29221d9a96bae0",
                    ),
                "data" to yamlObject(),
            ),
        )
        mode("single")
    }

fun turnStairLightsOff() =
    automation(
        id = "1780963707995",
        alias = "Stair lights off",
    ) {
        triggers(
            ikeaShortcutButtonShortPress(),
            downstairsButtonToggle(),
        )
        conditions(
            yamlObject(
                "condition" to "device",
                "type" to "is_on",
                "device_id" to "2c0f04abd6148843b1756b944ea925d7",
                "entity_id" to "c76155248c42d7a29d57b0938dbd49de",
                "domain" to "light",
                "for" to
                    yamlObject(
                        "hours" to 0,
                        "minutes" to 0,
                        "seconds" to 1,
                    ),
            ),
        )
        actions(
            turnOffLights(
                "light.stair_light_1",
                "light.stair_light_2",
                "light.dining_room_lamp",
            ),
        )
        mode("single")
    }

fun decreaseLampBrightness() =
    automation(
        id = "1780963899292",
        alias = "Decrease lamp brightness",
    ) {
        triggers(
            ikeaShortcutButtonRotatedLeft(),
        )
        actions(
            adjustLightBrightness("light.dining_room_lamp", brightnessStepPct = -20),
        )
        mode("single")
    }

fun increaseLampBrightness() =
    automation(
        id = "1780964087146",
        alias = "Increase lamp brightness",
    ) {
        triggers(
            ikeaShortcutButtonRotatedRight(),
        )
        actions(
            adjustLightBrightness("light.stair_light_1", brightnessStepPct = 50, continueOnError = true),
            adjustLightBrightness("light.stair_light_2", brightnessStepPct = 50, continueOnError = true),
            adjustLightBrightness("light.dining_room_lamp", brightnessStepPct = 20),
        )
        mode("single")
    }

fun toggleBedroomMikeLamplight() =
    automation(
        id = "1780965369367",
        alias = "Toggle mike lamplight",
    ) {
        triggers(
            bedroomMikeLamplightButtonToggle(),
        )
        actions(
            yamlObject(
                "type" to "toggle",
                "device_id" to "9f60192a08622db8c597cea034d075b1",
                "entity_id" to "d3075c2bb97112a2bd9cdc4bd388ba7a",
                "domain" to "switch",
            ),
        )
        mode("single")
    }

fun lightsFollowPowerOff() =
    automation(
        id = "1780973542501",
        alias = "Lights follow power off",
    ) {
        triggers(
            downstairsPowerSensorOffline(),
        )
        actions(
            turnOffLights("light.smartlight_4"),
        )
        mode("single")
    }

fun stairLightsOn() =
    automation(
        id = "1780975857816",
        alias = "Stairs lights on",
    ) {
        triggers(
            ikeaShortcutButtonShortPress(),
            downstairsButtonToggle(),
        )
        conditions(
            yamlObject(
                "condition" to "device",
                "type" to "is_off",
                "device_id" to "2c0f04abd6148843b1756b944ea925d7",
                "entity_id" to "c76155248c42d7a29d57b0938dbd49de",
                "domain" to "light",
                "for" to yamlObject("hours" to 0, "minutes" to 0, "seconds" to 1),
            ),
        )
        actions(
            turnOnLights(
                "light.stair_light_1",
                "light.stair_light_2",
                "light.dining_room_lamp",
            ),
        )
        mode("single")
    }

fun toggleDownstairsLamp() =
    automation(
        id = "toggle_downstairs_lamp",
        alias = "Toggle downstairs lamp",
    ) {
        triggers(
            ikeaShortcutButtonDoublePress(),
            downstairsButtonOn(),
        )
        actions(
            toggleLight("light.dining_room_lamp"),
        )
        mode("single")
    }

fun setLightNewColour(lightName: String) =
    automation(
        id = "${lightName}_lamp_colour",
        alias = "Set $lightName to new colour",
    ) {
        triggers(stateTrigger("input_number.downstairs_light_colour_index"))
        variables(colourVariables(includeDefaultColour = true))
        conditions(lightIsOn("light.$lightName"))
        actions(turnOnLightWithRgbColour("light.$lightName", NEXT_COLOUR_RGB_TEMPLATE))
        mode("single")
    }

fun advancedCycleColours() =
    automation(
        id = "1780986988887",
        alias = "Cycle stair light colours",
    ) {
        triggers(
            ikeaShortcutButtonLongPress(),
            downstairsButtonOff(),
        )
        variables(colourVariables())
        actions(advanceDownstairsColourIndex())
        mode("single")
    }

fun setLightColourWhenOn(lightName: String) =
    automation(
        id = "set_${lightName}_colour_when_on",
        alias = "Set the $lightName colour when turned on",
    ) {
        triggers(lightTurnedOnTrigger("light.$lightName"))
        variables(colourVariables(includeDefaultColour = true))
        actions(turnOnLightWithRgbColour("light.$lightName", NEXT_COLOUR_RGB_TEMPLATE))
    }

fun notifyHeatpumpCanBeTurnedOff() =
    automation(
        id = "1781210376062",
        alias = "Notify heat pump can be turned off",
    ) {
        triggers(
            yamlObject(
                "trigger" to "temperature.crossed_threshold",
                "target" to yamlObject("entity_id" to "sensor.temperature_humidity_sensor_1_temperature"),
                "options" to
                    yamlObject(
                        "behavior" to "each",
                        "for" to yamlObject("hours" to 0, "minutes" to 10, "seconds" to 0),
                        "threshold" to
                            yamlObject(
                                "type" to "above",
                                "value" to
                                    yamlObject(
                                        "active_choice" to "number",
                                        "number" to 18,
                                        "unit_of_measurement" to "°C",
                                    ),
                            ),
                    ),
            ),
        )
        conditions(
            yamlObject(
                "condition" to "time",
                "after" to "09:00:00",
                "before" to "17:00:00",
            ),
        )
        actions(
            yamlObject(
                "action" to "notify.send_message",
                "metadata" to yamlObject(),
                "target" to yamlObject("device_id" to "449719a7d011795e08e37c0f114f4771"),
                "data" to yamlObject("message" to "Downstairs heat reached threshold "),
            ),
        )
        mode("single")
    }

fun turnOffOfficeHeatpumpAutomatically() =
    automation(
        id = "1781216970827",
        alias = "Disable heatpump after reaching threshold",
    ) {
        triggers(
            yamlObject(
                "trigger" to "temperature.crossed_threshold",
                "target" to yamlObject("area_id" to "mike_s_office"),
                "options" to
                    yamlObject(
                        "behavior" to "each",
                        "threshold" to
                            yamlObject(
                                "type" to "above",
                                "value" to
                                    yamlObject(
                                        "active_choice" to "entity",
                                        "entity" to "input_number.mikes_office_target_heatpump_heat_temp",
                                    ),
                            ),
                        "for" to yamlObject("hours" to 0, "minutes" to 5, "seconds" to 0),
                    ),
            ),
        )
        conditions(
            yamlObject(
                "condition" to "climate.is_hvac_mode",
                "target" to
                    yamlObject(
                        "entity_id" to "climate.mike_s_office_heatpump_mike_s_office_mike_s_office_heater",
                    ),
                "options" to yamlObject("behavior" to "any", "hvac_mode" to yamlList("heat")),
            ),
        )
        actions(
            yamlObject(
                "action" to "climate.turn_off",
                "metadata" to yamlObject(),
                "target" to
                    yamlObject(
                        "entity_id" to "climate.mike_s_office_heatpump_mike_s_office_mike_s_office_heater",
                    ),
                "data" to yamlObject(),
            ),
        )
        mode("single")
    }

fun automations(): List<YamlObject> =
    yamlObjects(
        turnOffOfficeHeatpumpOnTimer(),
        turnStairLightsOff(),
        decreaseLampBrightness(),
        increaseLampBrightness(),
        toggleBedroomMikeLamplight(),
        lightsFollowPowerOff(),
        stairLightsOn(),
        toggleDownstairsLamp(),
        setLightNewColour("stair_light_1"),
        setLightNewColour("stair_light_2"),
        setLightNewColour("dining_room_lamp"),
        advancedCycleColours(),
        setLightColourWhenOn("stair_light_1"),
        setLightColourWhenOn("stair_light_2"),
        setLightColourWhenOn("dining_room_lamp"),
        notifyHeatpumpCanBeTurnedOff(),
        turnOffOfficeHeatpumpAutomatically(),
    )

private fun rgb(
    red: Int,
    green: Int,
    blue: Int,
): List<Int> = listOf(red, green, blue)

private fun colourVariables(includeDefaultColour: Boolean = false): YamlObject =
    if (includeDefaultColour) {
        yamlObject(
            "colour" to defaultColour,
            "colour_cycle" to colourCycle,
        )
    } else {
        yamlObject("colour_cycle" to colourCycle)
    }

private fun advanceDownstairsColourIndex(): YamlObject =
    yamlObject(
        "action" to "input_number.set_value",
        "entity_id" to "input_number.downstairs_light_colour_index",
        "data" to yamlObject("value" to NEXT_COLOUR_INDEX_TEMPLATE),
    )

private fun stateTrigger(entityId: String): YamlObject =
    yamlObject(
        "trigger" to "state",
        "entity_id" to entityId,
    )
