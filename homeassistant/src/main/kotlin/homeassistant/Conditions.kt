package homeassistant

fun orCondition(vararg conditions: Condition): Condition =
    LogicalCondition(
        condition = "or",
        conditions = conditions.toList(),
    )

fun notCondition(vararg conditions: Condition): Condition =
    LogicalCondition(
        condition = "not",
        conditions = conditions.toList(),
    )

fun timeCondition(
    after: String,
    before: String,
): Condition = TimeCondition(after = after, before = before)

fun washingMachineRanCondition() =
    GenericCondition(
        mapOf(
            "condition" to "switch.is_on",
            "target" to entityTarget("input_boolean.washing_machine_ran_today"),
            "options" to mapOf("behavior" to "any", "for" to Duration(minutes = 10)),
        ),
    )
