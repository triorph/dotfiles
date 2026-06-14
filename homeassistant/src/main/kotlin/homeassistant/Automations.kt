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
        triggers(timeTrigger("17:00:00"))
        conditions(orCondition(officeHeatpumpIsNotOff()))
        actions(turnOffOfficeHeatpumpDevice())
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
            lightDeviceIsOn(
                deviceId = "2c0f04abd6148843b1756b944ea925d7",
                entityId = "c76155248c42d7a29d57b0938dbd49de",
                duration = duration(seconds = 1),
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
            toggleSwitchDevice(
                deviceId = "9f60192a08622db8c597cea034d075b1",
                entityId = "d3075c2bb97112a2bd9cdc4bd388ba7a",
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
            lightDeviceIsOff(
                deviceId = "2c0f04abd6148843b1756b944ea925d7",
                entityId = "c76155248c42d7a29d57b0938dbd49de",
                duration = duration(seconds = 1),
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
            temperatureCrossedThresholdTrigger(
                target = entityTarget("sensor.temperature_humidity_sensor_1_temperature"),
                threshold = aboveNumberThreshold(18, unitOfMeasurement = "°C"),
                duration = duration(minutes = 10),
            ),
        )
        conditions(timeCondition(after = "09:00:00", before = "17:00:00"))
        actions(
            sendNotification(
                deviceId = "449719a7d011795e08e37c0f114f4771",
                message = "Downstairs heat reached threshold ",
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
            temperatureCrossedThresholdTrigger(
                target = areaTarget("mike_s_office"),
                threshold = aboveEntityThreshold("input_number.mikes_office_target_heatpump_heat_temp"),
                duration = duration(minutes = 5),
            ),
        )
        conditions(officeHeatpumpIsHeating())
        actions(turnOffOfficeHeatpumpEntity())
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
    setInputNumberValue(
        entityId = "input_number.downstairs_light_colour_index",
        value = NEXT_COLOUR_INDEX_TEMPLATE,
    )
