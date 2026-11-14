import com.android.build.api.variant.LibraryAndroidComponentsExtension

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
subprojects {
    project.evaluationDependsOn(":app")
    // BLE 5.5 declares SDK 33; Flutter's AndroidX dependencies require 34+.
    // Finalize the library DSL without changing a downloaded package.
    plugins.withId("com.android.library") {
        extensions.configure<LibraryAndroidComponentsExtension> {
            finalizeDsl { androidDsl -> androidDsl.compileSdk = 36 }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

