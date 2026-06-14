package homeassistant

import com.fasterxml.jackson.core.type.TypeReference
import com.fasterxml.jackson.databind.ObjectMapper
import com.fasterxml.jackson.dataformat.yaml.YAMLFactory
import com.fasterxml.jackson.module.kotlin.registerKotlinModule
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class AutomationsGeneratorTest {
    private val yamlMapper = ObjectMapper(YAMLFactory()).registerKotlinModule()

    @Test
    fun `generated YAML preserves kotlin automation ids and aliases`() {
        val generatedAutomations = parseAutomations(generateAutomationsYaml())

        assertEquals(
            expectedAutomationIds,
            generatedAutomations.idsByOrder(),
            "Generated automations should preserve the Kotlin automation ids and ordering.",
        )
        assertEquals(
            expectedAliasesById,
            generatedAutomations.aliasesById(),
            "Generated automations should preserve the Kotlin automation aliases.",
        )
    }

    @Test
    fun `generated YAML expands shared kotlin objects instead of emitting yaml anchors`() {
        val generatedYaml = generateAutomationsYaml()
        val generatedAutomations = parseAutomations(generatedYaml)

        assertFalse(generatedYaml.contains('&'), "Generated YAML should not contain YAML anchors.")
        assertFalse(generatedYaml.contains('*'), "Generated YAML should not contain YAML aliases.")

        val colourAutomationIds =
            listOf(
                "stair_light_1_lamp_colour",
                "stair_light_2_lamp_colour",
                "dining_room_lamp_lamp_colour",
                "set_stair_light_1_colour_when_on",
                "set_stair_light_2_colour_when_on",
                "set_dining_room_lamp_colour_when_on",
            )

        colourAutomationIds.forEach { automationId ->
            val automation = generatedAutomations.singleById(automationId)
            val variables = automation["variables"] as? Map<*, *>
            assertTrue(
                variables?.get("colour_cycle") is List<*>,
                "Automation $automationId should contain an expanded colour_cycle list.",
            )
        }
    }

    @Test
    fun `generated YAML can be parsed as a list of home assistant automations`() {
        val generatedAutomations = parseAutomations(generateAutomationsYaml())

        assertEquals(expectedAutomationIds.size, generatedAutomations.size)
        assertTrue(generatedAutomations.all { it.containsKey("id") })
        assertTrue(generatedAutomations.none { it.containsKey("definitions") })
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

    @Test
    fun `button with dial 2 controls mikes office generic thermostat`() {
        val automation = parseAutomations(generateAutomationsYaml()).singleById("turn_on_mikes_office_generic_thermostat")

        assertEquals(
            listOf(
                mapOf(
                    "device_id" to "16447bd2ede6b4941627e3bc14f58c13",
                    "domain" to "zha",
                    "type" to "remote_button_short_press",
                    "subtype" to "button",
                    "trigger" to "device",
                ),
            ),
            automation["triggers"],
        )
        assertEquals(
            listOf(
                mapOf(
                    "action" to "climate.turn_on",
                    "metadata" to emptyMap<String, Any>(),
                    "target" to mapOf("entity_id" to "climate.mike_s_office_heatpump_mike_s_office_mike_s_office_heater"),
                    "data" to emptyMap<String, Any>(),
                ),
            ),
            automation["actions"],
        )
        assertEquals("single", automation["mode"])

        val offAutomation = parseAutomations(generateAutomationsYaml()).singleById("turn_off_mikes_office_generic_thermostat")

        assertEquals(
            listOf(
                mapOf(
                    "device_id" to "16447bd2ede6b4941627e3bc14f58c13",
                    "domain" to "zha",
                    "type" to "remote_button_double_press",
                    "subtype" to "button_1",
                    "trigger" to "device",
                ),
            ),
            offAutomation["triggers"],
        )
        assertEquals(
            listOf(
                mapOf(
                    "action" to "climate.turn_off",
                    "metadata" to emptyMap<String, Any>(),
                    "target" to mapOf("entity_id" to "climate.mike_s_office_heatpump_mike_s_office_mike_s_office_heater"),
                    "data" to emptyMap<String, Any>(),
                ),
            ),
            offAutomation["actions"],
        )
        assertEquals("single", offAutomation["mode"])
    }

    private val expectedAutomationIds =
        listOf(
            "1780894997877",
            "1780963707995",
            "1780963899292",
            "1780964087146",
            "1780965369367",
            "1780973542501",
            "1780975857816",
            "toggle_downstairs_lamp",
            "stair_light_1_lamp_colour",
            "stair_light_2_lamp_colour",
            "dining_room_lamp_lamp_colour",
            "1780986988887",
            "set_stair_light_1_colour_when_on",
            "set_stair_light_2_colour_when_on",
            "set_dining_room_lamp_colour_when_on",
            "1781210376062",
            "1781216970827",
            "turn_on_mikes_office_generic_thermostat",
            "turn_off_mikes_office_generic_thermostat",
        )

    private val expectedAliasesById =
        mapOf(
            "1780894997877" to "Turn off office heatpump on timer",
            "1780963707995" to "Stair lights off",
            "1780963899292" to "Decrease lamp brightness",
            "1780964087146" to "Increase lamp brightness",
            "1780965369367" to "Toggle mike lamplight",
            "1780973542501" to "Lights follow power off",
            "1780975857816" to "Stairs lights on",
            "toggle_downstairs_lamp" to "Toggle downstairs lamp",
            "stair_light_1_lamp_colour" to "Set stair_light_1 to new colour",
            "stair_light_2_lamp_colour" to "Set stair_light_2 to new colour",
            "dining_room_lamp_lamp_colour" to "Set dining_room_lamp to new colour",
            "1780986988887" to "Cycle stair light colours",
            "set_stair_light_1_colour_when_on" to "Set the stair_light_1 colour when turned on",
            "set_stair_light_2_colour_when_on" to "Set the stair_light_2 colour when turned on",
            "set_dining_room_lamp_colour_when_on" to "Set the dining_room_lamp colour when turned on",
            "1781210376062" to "Notify heat pump can be turned off",
            "1781216970827" to "Disable heatpump after reaching threshold",
            "turn_on_mikes_office_generic_thermostat" to "Turn on Mike's office generic thermostat",
            "turn_off_mikes_office_generic_thermostat" to "Turn off Mike's office generic thermostat",
        )

    private fun parseAutomations(yaml: String): List<Map<String, Any?>> =
        yamlMapper.readValue(yaml, object : TypeReference<List<Map<String, Any?>>>() {})

    private fun List<Map<String, Any?>>.idsByOrder(): List<String> = map { it["id"].toString() }

    private fun List<Map<String, Any?>>.aliasesById(): Map<String, String> =
        filter { automation -> automation.containsKey("alias") }
            .associate { automation -> automation["id"].toString() to automation["alias"].toString() }

    private fun List<Map<String, Any?>>.singleById(id: String): Map<String, Any?> = single { it["id"] == id }
}
