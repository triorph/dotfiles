package homeassistant

fun orCondition(vararg conditions: YamlObject): YamlObject =
    yamlObject(
        "condition" to "or",
        "conditions" to yamlList(*conditions),
    )

fun notCondition(vararg conditions: YamlObject): YamlObject =
    yamlObject(
        "condition" to "not",
        "conditions" to yamlList(*conditions),
    )

fun timeCondition(
    after: String,
    before: String,
): YamlObject =
    yamlObject(
        "condition" to "time",
        "after" to after,
        "before" to before,
    )
