package homeassistant

import com.fasterxml.jackson.core.type.TypeReference
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse

class ModelSerializationTest {
    private val yamlMapper = HomeAssistantYaml.mapper

    @Test
    fun `automation model serializes to home assistant field names and omits empty optional sections`() {
        val yaml =
            yamlMapper.writeValueAsString(
                listOf(
                    Automation(
                        id = "example",
                        alias = "Example automation",
                        triggers = listOf(GenericTrigger(mapOf("trigger" to "time", "at" to "17:00:00"))),
                        actions = listOf(GenericAction(mapOf("action" to "test.action"))),
                        mode = "single",
                    ),
                ),
            )

        val automation = parseSingleAutomation(yaml)

        assertEquals("example", automation["id"])
        assertEquals("Example automation", automation["alias"])
        assertEquals("", automation["description"])
        assertEquals(listOf(mapOf("trigger" to "time", "at" to "17:00:00")), automation["triggers"])
        assertEquals(listOf(mapOf("action" to "test.action")), automation["actions"])
        assertEquals("single", automation["mode"])
        assertFalse(automation.containsKey("conditions"), "Empty conditions should be omitted.")
        assertFalse(automation.containsKey("variables"), "Empty variables should be omitted.")
    }

    @Test
    fun `typed trigger and action models serialize using home assistant yaml keys`() {
        val yaml =
            yamlMapper.writeValueAsString(
                listOf(
                    Automation(
                        id = "typed",
                        triggers =
                            listOf(
                                DeviceTrigger(
                                    deviceId = "button-device",
                                    domain = "zha",
                                    type = "remote_button_short_press",
                                    subtype = "button",
                                ),
                                EventTrigger(
                                    eventType = "zha_event",
                                    eventData = mapOf("command" to "toggle", "args" to emptyList<Any>()),
                                ),
                            ),
                        actions =
                            listOf(
                                LightAction(
                                    action = "light.turn_on",
                                    target = mapOf("entity_id" to "light.example"),
                                    data = mapOf("brightness_step_pct" to 50),
                                    continueOnError = true,
                                ),
                            ),
                    ),
                ),
            )

        val automation = parseSingleAutomation(yaml)

        assertEquals(
            listOf(
                mapOf(
                    "device_id" to "button-device",
                    "domain" to "zha",
                    "type" to "remote_button_short_press",
                    "subtype" to "button",
                    "trigger" to "device",
                ),
                mapOf(
                    "trigger" to "event",
                    "event_type" to "zha_event",
                    "event_data" to mapOf("command" to "toggle", "args" to emptyList<Any>()),
                ),
            ),
            automation["triggers"],
        )
        assertEquals(
            listOf(
                mapOf(
                    "action" to "light.turn_on",
                    "metadata" to emptyMap<String, Any>(),
                    "target" to mapOf("entity_id" to "light.example"),
                    "data" to mapOf("brightness_step_pct" to 50),
                    "continue_on_error" to true,
                ),
            ),
            automation["actions"],
        )
    }

    @Test
    fun `generic models preserve arbitrary home assistant maps`() {
        val yaml =
            yamlMapper.writeValueAsString(
                listOf(
                    Automation(
                        id = "generic",
                        triggers =
                            listOf(
                                GenericTrigger(
                                    mapOf(
                                        "trigger" to "temperature.crossed_threshold",
                                        "target" to mapOf("entity_id" to "sensor.example"),
                                    ),
                                ),
                            ),
                        conditions = listOf(GenericCondition(mapOf("condition" to "time", "after" to "09:00:00"))),
                        actions = listOf(GenericAction(mapOf("action" to "notify.send_message"), continueOnError = true)),
                    ),
                ),
            )

        val automation = parseSingleAutomation(yaml)

        assertEquals(
            listOf(mapOf("trigger" to "temperature.crossed_threshold", "target" to mapOf("entity_id" to "sensor.example"))),
            automation["triggers"],
        )
        assertEquals(listOf(mapOf("condition" to "time", "after" to "09:00:00")), automation["conditions"])
        assertEquals(listOf(mapOf("action" to "notify.send_message", "continue_on_error" to true)), automation["actions"])
    }

    private fun parseSingleAutomation(yaml: String): Map<String, Any?> =
        yamlMapper.readValue(yaml, object : TypeReference<List<Map<String, Any?>>>() {}).single()
}
