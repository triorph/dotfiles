package homeassistant

import java.nio.file.Path
import kotlin.io.path.createDirectories
import kotlin.io.path.writeText

fun generateAutomationsYaml(): String = HomeAssistantYaml.mapper.writeValueAsString(automations())

fun main(args: Array<String>) {
    require(args.size == 1) { "Expected output path argument." }

    val output = Path.of(args.single())
    output.parent?.createDirectories()
    output.writeText(generateAutomationsYaml())
}
