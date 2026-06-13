package homeassistant

import com.fasterxml.jackson.databind.ObjectMapper
import com.fasterxml.jackson.dataformat.yaml.YAMLFactory
import com.fasterxml.jackson.dataformat.yaml.YAMLGenerator
import com.fasterxml.jackson.module.kotlin.registerKotlinModule
import java.nio.file.Path
import kotlin.io.path.createDirectories
import kotlin.io.path.writeText

private val yamlMapper = ObjectMapper(
    YAMLFactory.builder()
        .disable(YAMLGenerator.Feature.WRITE_DOC_START_MARKER)
        .disable(YAMLGenerator.Feature.USE_NATIVE_OBJECT_ID)
        .disable(YAMLGenerator.Feature.USE_NATIVE_TYPE_ID)
        .build()
).registerKotlinModule()

fun generateAutomationsYaml(): String = yamlMapper.writeValueAsString(automations())

fun main(args: Array<String>) {
    require(args.size == 1) { "Expected output path argument." }

    val output = Path.of(args.single())
    output.parent?.createDirectories()
    output.writeText(generateAutomationsYaml())
}
