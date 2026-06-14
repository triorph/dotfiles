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

@JsonPropertyOrder("trigger", "at")
data class TimeTrigger(
    val at: String,
) : Trigger {
    val trigger: String = "time"
}

@JsonPropertyOrder("trigger", "entity_id")
data class StateTrigger(
    val entityId: String,
) : Trigger {
    val trigger: String = "state"
}

@JsonPropertyOrder("trigger", "target")
data class LightTurnedOnTrigger(
    val target: Target,
) : Trigger {
    val trigger: String = "light.turned_on"
}

@JsonPropertyOrder("condition", "conditions")
data class LogicalCondition(
    val condition: String,
    val conditions: List<Condition>,
) : Condition

@JsonPropertyOrder("condition", "after", "before")
data class TimeCondition(
    val after: String,
    val before: String,
) : Condition {
    val condition: String = "time"
}

@JsonPropertyOrder("condition", "target")
data class LightIsOnCondition(
    val target: Target,
) : Condition {
    val condition: String = "light.is_on"
}

@JsonInclude(JsonInclude.Include.NON_EMPTY)
@JsonPropertyOrder("action", "metadata", "target", "data", "continue_on_error")
data class LightAction(
    val action: String,
    @get:JsonInclude(JsonInclude.Include.ALWAYS)
    val metadata: Map<String, Any?> = emptyMap(),
    val target: Target,
    @get:JsonInclude(JsonInclude.Include.ALWAYS)
    val data: Map<String, Any?> = emptyMap(),
    override val continueOnError: Boolean? = null,
) : BaseAction(continueOnError)

@JsonInclude(JsonInclude.Include.NON_EMPTY)
@JsonPropertyOrder("action", "metadata", "target", "data", "continue_on_error")
data class ServiceAction(
    val action: String,
    @get:JsonInclude(JsonInclude.Include.ALWAYS)
    val metadata: Map<String, Any?> = emptyMap(),
    val target: Target? = null,
    @get:JsonInclude(JsonInclude.Include.ALWAYS)
    val data: Map<String, Any?> = emptyMap(),
    override val continueOnError: Boolean? = null,
) : BaseAction(continueOnError)

interface Target

data class EntityTarget(
    val entityId: String,
) : Target

data class AreaTarget(
    val areaId: String,
) : Target

data class DeviceTarget(
    val deviceId: String,
) : Target

data class GenericTarget(
    @get:JsonIgnore
    val values: Map<String, Any?>,
) : Target {
    @JsonAnyGetter
    fun properties(): Map<String, Any?> = values
}

data class Duration(
    val hours: Int = 0,
    val minutes: Int = 0,
    val seconds: Int = 0,
)

data class AboveThreshold(
    val value: Any,
) {
    val type: String = "above"
}

data class NumberThresholdValue(
    val activeChoice: String = "number",
    val number: Int,
    val unitOfMeasurement: String? = null,
)

data class EntityThresholdValue(
    val activeChoice: String = "entity",
    val entity: String,
)

@JsonPropertyOrder("behavior", "threshold", "for")
data class TemperatureThresholdOptions(
    val behavior: String = "each",
    val threshold: AboveThreshold,
    @get:com.fasterxml.jackson.annotation.JsonProperty("for")
    @get:JsonInclude(JsonInclude.Include.NON_NULL)
    val duration: Duration? = null,
)

@JsonPropertyOrder("trigger", "target", "options")
data class TemperatureCrossedThresholdTrigger(
    val target: Target,
    val options: TemperatureThresholdOptions,
) : Trigger {
    val trigger: String = "temperature.crossed_threshold"
}

@JsonPropertyOrder("condition", "type", "device_id", "entity_id", "domain", "for")
data class DeviceCondition(
    val type: String,
    val deviceId: String,
    val entityId: String,
    val domain: String,
    @get:com.fasterxml.jackson.annotation.JsonProperty("for")
    @get:JsonInclude(JsonInclude.Include.NON_NULL)
    val duration: Duration? = null,
) : Condition {
    val condition: String = "device"
}

@JsonPropertyOrder("condition", "device_id", "domain", "entity_id", "type", "hvac_mode")
data class ClimateDeviceHvacModeCondition(
    val deviceId: String,
    val domain: String = "climate",
    val entityId: String,
    val type: String = "is_hvac_mode",
    val hvacMode: String,
) : Condition {
    val condition: String = "device"
}

@JsonPropertyOrder("condition", "target", "options")
data class ClimateHvacModeCondition(
    val target: Target,
    val options: Map<String, Any?>,
) : Condition {
    val condition: String = "climate.is_hvac_mode"
}

@JsonPropertyOrder("action", "entity_id", "data", "continue_on_error")
data class InputNumberSetValueAction(
    val entityId: String,
    val data: Map<String, Any?>,
    override val continueOnError: Boolean? = null,
) : BaseAction(continueOnError) {
    val action: String = "input_number.set_value"
}

@JsonPropertyOrder("type", "device_id", "entity_id", "domain")
data class SwitchDeviceAction(
    val type: String,
    val deviceId: String,
    val entityId: String,
) : Action {
    val domain: String = "switch"
}
