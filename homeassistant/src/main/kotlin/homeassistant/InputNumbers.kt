package homeassistant

fun setInputNumberValue(
    entityId: String,
    value: String,
): Action =
    InputNumberSetValueAction(
        entityId = entityId,
        data = yamlObject("value" to value),
    )
