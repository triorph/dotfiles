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
