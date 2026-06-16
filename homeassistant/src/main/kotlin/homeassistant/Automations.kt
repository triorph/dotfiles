package homeassistant

fun turnOffOfficeHeatpumpOnTimer() =
    automation(
        id = "timer_office_heatpump_off",
        alias = "Turn off office heatpump on timer",
    ) {
        triggers(timeTrigger("17:00:00"))
        conditions(officeHeatpumpIsOn())
        actions(turnOffOfficeHeatpumpEntity())
    }

fun decreaseLampBrightness() =
    automation(
        id = "decrease_downstairs_lamp_brightness",
        alias = "Downstairs lamp - decrease brightness when turning button left",
    ) {
        triggers(downstairsDialTurnLeft())
        actions(
            adjustLightBrightness("light.dining_room_lamp", brightnessStepPct = -20),
        )
    }

fun increaseLampBrightness() =
    automation(
        id = "increase_downstairs_lamp_brightness",
        alias = "Downstairs lamp - increase lamp brightness when turning button right",
    ) {
        triggers(downstairsDialTurnRight())
        actions(
            adjustLightBrightness("light.dining_room_lamp", brightnessStepPct = 20),
        )
    }

fun toggleBedroomMikeLamplight() =
    automation(
        id = "toggle_mike_bedroom_lamp",
        alias = "Mike bedroom lamp - toggle when press buttons",
    ) {
        triggers(
            bedroomButtonClick(),
            upstairsButtonClick(),
        )
        actions(toggleMikeLamp())
    }

fun toggleDownstairsLamp() =
    automation(
        id = "toggle_downstairs_lamp",
        alias = "Downstairs lamp - toggle on when double press buttons",
    ) {
        triggers(
            downstairsDialDoubleClick(),
            upstairsButtonDoubleClick(),
        )
        actions(
            toggleLight("light.dining_room_lamp"),
        )
    }

fun setLightNewColour(lightName: String) =
    automation(
        id = "${lightName}_lamp_colour",
        alias = "$lightName - Set to new colour",
    ) {
        triggers(stateTrigger("input_number.downstairs_light_colour_index"))
        variables(colourVariables(includeDefaultColour = true))
        conditions(lightIsOn("light.$lightName"))
        actions(turnOnLightWithRgbColour("light.$lightName"))
    }

fun advancedCycleColours() =
    automation(
        id = "cycle_light_colours",
        alias = "Cycle light colours",
    ) {
        triggers(
            downstairsDialHold(),
            upstairsButtonHold(),
        )
        variables(colourVariables())
        actions(advanceDownstairsColourIndex())
    }

fun setLightColourWhenOn(lightName: String) =
    automation(
        id = "set_${lightName}_colour_when_on",
        alias = "Set the $lightName colour when turned on",
    ) {
        triggers(lightTurnedOnTrigger("light.$lightName"))
        variables(colourVariables(includeDefaultColour = true))
        actions(turnOnLightWithRgbColour("light.$lightName"))
    }

fun notifyHeatpumpCanBeTurnedOff() =
    automation(
        id = "heatpump_notify_turn_off",
        alias = "Downstairs heat pump - notify can be turned off at 18 degrees",
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
            notifyMikesPhone(
                message = "Downstairs heat reached threshold ",
            ),
        )
    }

fun turnOnMikesOfficeGenericThermostat() =
    automation(
        id = "turn_on_mikes_office_generic_thermostat",
        alias = "Mike's office thermostat - Turn on when clicking office dial",
    ) {
        triggers(officeDialClick())
        actions(turnOnOfficeHeatpumpEntity())
    }

fun turnOffMikesOfficeGenericThermostat() =
    automation(
        id = "turn_off_mikes_office_generic_thermostat",
        alias = "Mike's office thermostat - turn off when double-clicking office dial",
    ) {
        triggers(officeDialDoubleClick())
        actions(turnOffOfficeHeatpumpEntity())
    }

fun washingMachineRan() =
    automation("washing_machine_ran", "Washing machine - Set ran today") {
        triggers(washingMachineCurrentAboveThresholdTrigger())
        actions(
            GenericAction(
                mapOf(
                    "action" to "input_boolean.turn_on",
                    "target" to entityTarget("input_boolean.washing_machine_ran_today"),
                ),
            ),
        )
    }

fun hangUpWashing() =
    automation("hang_up_washing", "Washing machine - Hang up the washing") {
        triggers(washingMachineCurrentBelowThresholdTrigger())
        conditions(washingMachineRanCondition())
        actions(notifyMikesPhone("The washing machine has finished. Hang up the washing."))
    }

fun bringInWashing() =
    automation("bring_in_washing", "Washing machine - Bring in the washing") {
        triggers(sunsetTrigger())
        conditions(washingMachineRanCondition())
        actions(
            GenericAction(
                mapOf(
                    "action" to "input_boolean.turn_off",
                    "target" to entityTarget("input_boolean.washing_machine_ran_today"),
                ),
            ),
            notifyMikesPhone("Bring in the washing"),
        )
    }

fun automations(): List<Automation> =
    listOf(
        turnOffOfficeHeatpumpOnTimer(),
        decreaseLampBrightness(),
        increaseLampBrightness(),
        toggleBedroomMikeLamplight(),
        toggleDownstairsLamp(),
        setLightNewColour("dining_room_lamp"),
        advancedCycleColours(),
        notifyHeatpumpCanBeTurnedOff(),
        turnOnMikesOfficeGenericThermostat(),
        turnOffMikesOfficeGenericThermostat(),
        bringInWashing(),
        hangUpWashing(),
        washingMachineRan(),
    )
