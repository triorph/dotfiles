plugins {
    kotlin("jvm") version "2.2.21"
}

group = "homeassistant"
version = "0.1.0"

kotlin {
    jvmToolchain(17)
}

dependencies {
    implementation("com.fasterxml.jackson.core:jackson-databind:2.20.1")
    implementation("com.fasterxml.jackson.dataformat:jackson-dataformat-yaml:2.20.1")
    implementation("com.fasterxml.jackson.module:jackson-module-kotlin:2.20.1")

    testImplementation(kotlin("test"))
}

tasks.test {
    useJUnitPlatform()
}

val generatedAutomationsFile = layout.buildDirectory.file("generated/automations.yaml")

tasks.register<JavaExec>("generateAutomations") {
    group = "homeassistant"
    description = "Generates Home Assistant automations YAML into build/generated/automations.yaml."

    classpath = sourceSets["main"].runtimeClasspath
    mainClass.set("homeassistant.AutomationsGeneratorKt")
    args(generatedAutomationsFile.get().asFile.absolutePath)
    outputs.file(generatedAutomationsFile)
}
