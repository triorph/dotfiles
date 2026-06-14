package homeassistant

fun setInputNumberValue(
    entityId: String,
    value: String,
): YamlObject =
    yamlObject(
        "action" to "input_number.set_value",
        "entity_id" to entityId,
        "data" to yamlObject("value" to value),
    )
