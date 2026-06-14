package homeassistant

import com.fasterxml.jackson.annotation.JsonAnyGetter
import com.fasterxml.jackson.annotation.JsonIgnore
import com.fasterxml.jackson.annotation.JsonInclude
import com.fasterxml.jackson.annotation.JsonPropertyOrder

@JsonInclude(JsonInclude.Include.NON_EMPTY)
@JsonPropertyOrder("id", "alias", "description", "triggers", "conditions", "variables", "actions", "mode")
data class Automation(
    val id: String,
    val alias: String? = null,
    @get:JsonInclude(JsonInclude.Include.ALWAYS)
    val description: String = "",
    val triggers: List<Trigger> = emptyList(),
    val conditions: List<Condition> = emptyList(),
    val variables: Map<String, Any?> = emptyMap(),
    val actions: List<Action> = emptyList(),
    val mode: String? = null,
)

interface Trigger

interface Condition

interface Variable

interface Action

abstract class BaseAction(
    @get:JsonInclude(JsonInclude.Include.NON_NULL)
    open val continueOnError: Boolean? = null,
) : Action

data class GenericTrigger(
    @get:JsonIgnore
    val values: Map<String, Any?>,
) : Trigger {
    @JsonAnyGetter
    fun properties(): Map<String, Any?> = values
}

data class GenericCondition(
    @get:JsonIgnore
    val values: Map<String, Any?>,
) : Condition {
    @JsonAnyGetter
    fun properties(): Map<String, Any?> = values
}

data class GenericAction(
    @get:JsonIgnore
    val values: Map<String, Any?>,
    override val continueOnError: Boolean? = null,
) : BaseAction(continueOnError) {
    @JsonAnyGetter
    fun properties(): Map<String, Any?> = values
}

@JsonPropertyOrder("device_id", "domain", "type", "subtype", "trigger")
data class DeviceTrigger(
    val deviceId: String,
    val domain: String,
    val type: String,
    val subtype: String,
) : Trigger {
    val trigger: String = "device"
}

@JsonPropertyOrder("trigger", "event_type", "event_data")
data class EventTrigger(
    val eventType: String,
    val eventData: Map<String, Any?>,
) : Trigger {
    val trigger: String = "event"
}

@JsonInclude(JsonInclude.Include.NON_EMPTY)
@JsonPropertyOrder("action", "metadata", "target", "data", "continue_on_error")
data class LightAction(
    val action: String,
    @get:JsonInclude(JsonInclude.Include.ALWAYS)
    val metadata: Map<String, Any?> = emptyMap(),
    val target: Map<String, Any?>,
    @get:JsonInclude(JsonInclude.Include.ALWAYS)
    val data: Map<String, Any?> = emptyMap(),
    override val continueOnError: Boolean? = null,
) : BaseAction(continueOnError)
