package homeassistant

typealias YamlObject = MutableMap<String, Any?>

fun yamlObject(vararg entries: Pair<String, Any?>): YamlObject = mutableMapOf(*entries)

fun yamlList(vararg values: Any?): List<Any?> = values.toList()

fun yamlObjects(vararg values: YamlObject): List<YamlObject> = values.toList()

fun automation(
    id: String,
    alias: String? = null,
    block: YamlObject.() -> Unit,
): YamlObject =
    yamlObject("id" to id, "description" to "").apply {
        if (alias != null) {
            this["alias"] = alias
        }
        block()
    }

fun YamlObject.description(value: String) {
    this["description"] = value
}

private fun YamlObject.assignListTo(
    key: String,
    vararg values: Any,
) = values.toList().takeIf { it.isNotEmpty() }?.let { this[key] = it }

fun YamlObject.triggers(vararg values: Any) {
    this.assignListTo("triggers", values)
}

fun YamlObject.conditions(vararg values: Any) {
    this.assignListTo("conditions", values)
}

fun YamlObject.actions(vararg values: Any) {
    this.assignListTo("actions", values)
}

fun YamlObject.variables(vararg values: Any) {
    values.toList().takeIf { it.isNotEmpty() }?.let {
        this["variables"] = if (it.size == 1 && it.single() is Map<*, *>) it.single() else it
    }
}

fun YamlObject.mode(value: String) {
    this["mode"] = value
}
