package homeassistant

import com.fasterxml.jackson.core.type.TypeReference
import com.fasterxml.jackson.databind.ObjectMapper
import com.fasterxml.jackson.dataformat.yaml.YAMLFactory
import com.fasterxml.jackson.module.kotlin.registerKotlinModule
import kotlin.io.path.Path
import kotlin.io.path.readText
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class AutomationsGeneratorTest {
    private val yamlMapper = ObjectMapper(YAMLFactory()).registerKotlinModule()

    @Test
    fun `generated YAML preserves automation ids and aliases from the current file`() {
        val currentAutomations = parseAutomations(Path("automations.yaml").readText())
        val generatedAutomations = parseAutomations(generateAutomationsYaml())

        assertEquals(
            currentAutomations.idsByOrder(),
            generatedAutomations.idsByOrder(),
            "Generated automations should preserve the current automation ids and ordering."
        )
        assertEquals(
            currentAutomations.aliasesById(),
            generatedAutomations.aliasesById(),
            "Generated automations should preserve the current automation aliases for entries that have aliases."
        )
    }

    @Test
    fun `generated YAML expands shared kotlin objects instead of emitting yaml anchors`() {
        val generatedYaml = generateAutomationsYaml()
        val generatedAutomations = parseAutomations(generatedYaml)

        assertFalse(generatedYaml.contains('&'), "Generated YAML should not contain YAML anchors.")
        assertFalse(generatedYaml.contains('*'), "Generated YAML should not contain YAML aliases.")

        val colourAutomationIds = listOf(
            "stair_light_1_lamp_colour",
            "stair_light_2_lamp_colour",
            "downstairs_lamp_colour",
            "set_stair_light_1_colour_when_on",
            "set_stair_light_2_colour_when_on",
        )

        colourAutomationIds.forEach { automationId ->
            val automation = generatedAutomations.singleById(automationId)
            val variables = automation["variables"] as? Map<*, *>
            assertTrue(
                variables?.get("colour_cycle") is List<*>,
                "Automation $automationId should contain an expanded colour_cycle list."
            )
        }
    }

    @Test
    fun `generated YAML can be parsed as a list of home assistant automations`() {
        val currentAutomations = parseAutomations(Path("automations.yaml").readText())
        val generatedAutomations = parseAutomations(generateAutomationsYaml())

        assertEquals(currentAutomations.size, generatedAutomations.size)
        assertTrue(generatedAutomations.all { it.containsKey("id") })
    }

    private fun parseAutomations(yaml: String): List<Map<String, Any?>> =
        yamlMapper.readValue(yaml, object : TypeReference<List<Map<String, Any?>>>() {})

    private fun List<Map<String, Any?>>.idsByOrder(): List<String> =
        map { it["id"].toString() }

    private fun List<Map<String, Any?>>.aliasesById(): Map<String, String> =
        filter { automation -> automation.containsKey("alias") }
            .associate { automation -> automation["id"].toString() to automation["alias"].toString() }

    private fun List<Map<String, Any?>>.singleById(id: String): Map<String, Any?> =
        single { it["id"] == id }
}
