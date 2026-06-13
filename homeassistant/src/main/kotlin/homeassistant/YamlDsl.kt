package homeassistant

typealias YamlObject = LinkedHashMap<String, Any?>

fun yamlObject(vararg entries: Pair<String, Any?>): YamlObject =
    linkedMapOf(*entries)

fun yamlList(vararg values: Any?): List<Any?> =
    values.toList()

fun yamlObjects(vararg values: YamlObject): List<YamlObject> =
    values.toList()

fun automation(id: String, alias: String? = null, block: YamlObject.() -> Unit): YamlObject =
    yamlObject("id" to id).apply {
        if (alias != null) {
            this["alias"] = alias
        }
        block()
    }

fun YamlObject.description(value: String) {
    this["description"] = value
}

fun YamlObject.triggers(value: Any?) {
    this["triggers"] = value
}

fun YamlObject.conditions(value: Any?) {
    this["conditions"] = value
}

fun YamlObject.actions(value: Any?) {
    this["actions"] = value
}

fun YamlObject.variables(value: Any?) {
    this["variables"] = value
}

fun YamlObject.mode(value: String) {
    this["mode"] = value
}
