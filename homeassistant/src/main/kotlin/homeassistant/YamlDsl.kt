package homeassistant

typealias YamlObject = MutableMap<String, Any?>

fun yamlObject(vararg entries: Pair<String, Any?>): YamlObject = mutableMapOf(*entries)

fun yamlList(vararg values: Any?): List<Any?> = values.toList()

fun automation(
    id: String,
    alias: String? = null,
    block: AutomationBuilder.() -> Unit,
): Automation =
    AutomationBuilder(id = id, alias = alias)
        .apply(block)
        .build()

class AutomationBuilder(
    private val id: String,
    private val alias: String?,
) {
    private var description: String = ""
    private val triggers = mutableListOf<Trigger>()
    private val conditions = mutableListOf<Condition>()
    private var variables: Map<String, Any?> = emptyMap()
    private val actions = mutableListOf<Action>()
    private var mode: String? = "single"

    fun description(value: String) {
        description = value
    }

    fun triggers(vararg values: Trigger) {
        triggers += values
    }

    fun conditions(vararg values: Condition) {
        conditions += values
    }

    fun actions(vararg values: Action) {
        actions += values
    }

    fun variables(value: Map<String, Any?>) {
        variables = value
    }

    fun mode(value: String) {
        mode = value
    }

    fun build(): Automation =
        Automation(
            id = id,
            alias = alias,
            description = description,
            triggers = triggers,
            conditions = conditions,
            variables = variables,
            actions = actions,
            mode = mode,
        )
}
