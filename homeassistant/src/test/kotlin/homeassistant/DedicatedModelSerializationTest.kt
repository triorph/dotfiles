package homeassistant

import com.fasterxml.jackson.core.type.TypeReference
import kotlin.test.Test
import kotlin.test.assertEquals

class DedicatedModelSerializationTest {
    private val yamlMapper = HomeAssistantYaml.mapper

    @Test
    fun `target and duration models serialize to home assistant maps`() {
        assertEquals(mapOf("entity_id" to "light.example"), serialize(EntityTarget("light.example")))
        assertEquals(mapOf("area_id" to "office"), serialize(AreaTarget("office")))
        assertEquals(mapOf("device_id" to "device-1"), serialize(DeviceTarget("device-1")))
        assertEquals(mapOf("hours" to 0, "minutes" to 5, "seconds" to 0), serialize(Duration(minutes = 5)))
    }

    @Test
    fun `temperature crossed threshold trigger serializes without generic maps`() {
        val automation =
            Automation(
                id = "temperature",
                triggers =
                    listOf(
                        TemperatureCrossedThresholdTrigger(
                            target = EntityTarget("sensor.temperature"),
                            options =
                                TemperatureThresholdOptions(
                                    threshold = AboveThreshold(NumberThresholdValue(number = 18, unitOfMeasurement = "°C")),
                                    duration = Duration(minutes = 10),
                                ),
                        ),
                    ),
            )

        val trigger = parseSingleAutomation(yamlMapper.writeValueAsString(listOf(automation)))["triggers"] as List<*>

        assertEquals(
            mapOf(
                "trigger" to "temperature.crossed_threshold",
                "target" to mapOf("entity_id" to "sensor.temperature"),
                "options" to
                    mapOf(
                        "behavior" to "each",
                        "threshold" to
                            mapOf(
                                "type" to "above",
                                "value" to
                                    mapOf(
                                        "active_choice" to "number",
                                        "number" to 18,
                                        "unit_of_measurement" to "°C",
                                    ),
                            ),
                        "for" to mapOf("hours" to 0, "minutes" to 10, "seconds" to 0),
                    ),
            ),
            trigger.single(),
        )
    }

    @Test
    fun `device condition model serializes duration as for`() {
        val automation =
            Automation(
                id = "condition",
                conditions =
                    listOf(
                        DeviceCondition(
                            type = "is_off",
                            deviceId = "device-1",
                            entityId = "entity-1",
                            domain = "light",
                            duration = Duration(seconds = 1),
                        ),
                    ),
            )

        val condition = parseSingleAutomation(yamlMapper.writeValueAsString(listOf(automation)))["conditions"] as List<*>

        assertEquals(
            mapOf(
                "condition" to "device",
                "type" to "is_off",
                "device_id" to "device-1",
                "entity_id" to "entity-1",
                "domain" to "light",
                "for" to mapOf("hours" to 0, "minutes" to 0, "seconds" to 1),
            ),
            condition.single(),
        )
    }

    @Test
    fun `switch device action model replaces generic action map`() {
        val automation =
            Automation(
                id = "switch",
                actions =
                    listOf(
                        SwitchDeviceAction(
                            type = "toggle",
                            deviceId = "device-1",
                            entityId = "entity-1",
                        ),
                    ),
            )

        val action = parseSingleAutomation(yamlMapper.writeValueAsString(listOf(automation)))["actions"] as List<*>

        assertEquals(
            mapOf(
                "type" to "toggle",
                "device_id" to "device-1",
                "entity_id" to "entity-1",
                "domain" to "switch",
            ),
            action.single(),
        )
    }

    private fun serialize(value: Any): Map<String, Any?> =
        yamlMapper.readValue(yamlMapper.writeValueAsString(value), object : TypeReference<Map<String, Any?>>() {})

    private fun parseSingleAutomation(yaml: String): Map<String, Any?> =
        yamlMapper.readValue(yaml, object : TypeReference<List<Map<String, Any?>>>() {}).single()
}
