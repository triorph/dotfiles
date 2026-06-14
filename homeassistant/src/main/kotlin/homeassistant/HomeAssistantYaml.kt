package homeassistant

import com.fasterxml.jackson.databind.ObjectMapper
import com.fasterxml.jackson.databind.PropertyNamingStrategies
import com.fasterxml.jackson.dataformat.yaml.YAMLFactory
import com.fasterxml.jackson.dataformat.yaml.YAMLGenerator
import com.fasterxml.jackson.module.kotlin.registerKotlinModule

object HomeAssistantYaml {
    val mapper: ObjectMapper =
        ObjectMapper(
            YAMLFactory
                .builder()
                .disable(YAMLGenerator.Feature.WRITE_DOC_START_MARKER)
                .disable(YAMLGenerator.Feature.USE_NATIVE_OBJECT_ID)
                .disable(YAMLGenerator.Feature.USE_NATIVE_TYPE_ID)
                .build(),
        ).registerKotlinModule()
            .setPropertyNamingStrategy(PropertyNamingStrategies.SNAKE_CASE)
}
