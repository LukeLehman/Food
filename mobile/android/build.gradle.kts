import com.android.build.gradle.LibraryExtension

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// Fallback namespace for Android library subprojects missing one (AGP 8+)
// Configures during plugin application (no afterEvaluate).
subprojects {
    plugins.withId("com.android.library") {
        extensions.configure<LibraryExtension> {
            // If the library didn't set a namespace, derive a stable one from the project name.
            if (namespace.isNullOrBlank()) {
                namespace = "com.ironstronginitiative." + project.name.replace("-", "_")
            }
        }
    }
}
