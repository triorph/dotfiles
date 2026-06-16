package homeassistant

import com.fasterxml.jackson.core.type.TypeReference
import com.fasterxml.jackson.databind.ObjectMapper
import com.fasterxml.jackson.dataformat.yaml.YAMLFactory
import com.fasterxml.jackson.module.kotlin.registerKotlinModule
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class AutomationsGeneratorTest {
    private val yamlMapper = ObjectMapper(YAMLFactory()).registerKotlinModule()

    @Test
    fun `generated YAML preserves kotlin automation ids and aliases`() {
        val generatedAutomations = parseAutomations(generateAutomationsYaml())

        assertEquals(
            expectedAutomationIds,
            generatedAutomations.idsByOrder(),
            "Generated automations should preserve the Kotlin automation ids",
        )
        assertEquals(
            expectedAliasesById,
            generatedAutomations.aliasesById(),
            "Generated automations should preserve the Kotlin automation aliases.",
        )
    }

    @Test
    fun `generated YAML can be parsed as a list of home assistant automations`() {
        val generatedAutomations = parseAutomations(generateAutomationsYaml())

        assertEquals(expectedAutomationIds.size, generatedAutomations.size)
        assertTrue(generatedAutomations.all { it.containsKey("id") })
    }

    @Test
    fun `generated variables serialize as maps`() {
        parseAutomations(generateAutomationsYaml())
            .filter { it.containsKey("variables") }
            .forEach { automation ->
                assertTrue(
                    automation["variables"] is Map<*, *>,
                    "Variables should serialize as a map for ${automation["id"]}.",
                )
            }
    }

    private val expectedAliasesById =
        mapOf(
            "timer_office_heatpump_off" to "Turn off office heatpump on timer",
            "decrease_downstairs_lamp_brightness" to "Downstairs lamp - decrease brightness when turning button left",
            "increase_downstairs_lamp_brightness" to "Downstairs lamp - increase lamp brightness when turning button right",
            "toggle_mike_bedroom_lamp" to "Mike bedroom lamp - toggle when press buttons",
            "toggle_downstairs_lamp" to "Downstairs lamp - toggle on when double press buttons",
            "dining_room_lamp_lamp_colour" to "dining_room_lamp - Set to new colour",
            "cycle_light_colours" to "Cycle light colours",
            "heatpump_notify_turn_off" to "Downstairs heat pump - notify can be turned off at 18 degrees",
            "turn_on_mikes_office_generic_thermostat" to "Mike's office thermostat - Turn on when clicking office dial",
            "turn_off_mikes_office_generic_thermostat" to "Mike's office thermostat - turn off when double-clicking office dial",
            "bring_in_washing" to "Washing machine - Bring in the washing",
            "hang_up_washing" to "Washing machine - Hang up the washing",
            "washing_machine_ran" to "Washing machine - Set ran today",
        )

    private val expectedAutomationIds =
        expectedAliasesById.keys

    private fun parseAutomations(yaml: String): List<Map<String, Any?>> =
        yamlMapper.readValue(yaml, object : TypeReference<List<Map<String, Any?>>>() {})

    private fun List<Map<String, Any?>>.idsByOrder(): Set<String> = map { it["id"].toString() }.toSet()

    private fun List<Map<String, Any?>>.aliasesById(): Map<String, String> =
        filter { automation -> automation.containsKey("alias") }
            .associate { automation -> automation["id"].toString() to automation["alias"].toString() }

    private fun List<Map<String, Any?>>.singleById(id: String): Map<String, Any?> = single { it["id"] == id }
}
