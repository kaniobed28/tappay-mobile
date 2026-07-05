allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
// Some plugins (e.g. nfc_manager 3.x) hardcode an old compileSdk (31) while pulling in
// AndroidX libs that require 34+. Force every Android library module to compile against 36.
// Uses withGroovyBuilder so we don't need the AGP types on the root buildscript classpath.
fun Project.forceCompileSdk36() {
    val androidExt = extensions.findByName("android") ?: return
    androidExt.withGroovyBuilder { "compileSdkVersion"(36) }
}

subprojects {
    // Register the override before evaluationDependsOn (which can trigger evaluation).
    if (state.executed) forceCompileSdk36() else afterEvaluate { forceCompileSdk36() }
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
