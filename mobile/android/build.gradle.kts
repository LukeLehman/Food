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

// Fallback namespace setter for Android library subprojects missing `namespace` (AGP 8+ requirement)
subprojects {
    afterEvaluate {
        val androidExt = extensions.findByName("android") ?: return@afterEvaluate
        val clazz = androidExt.javaClass
        val getNs = try { clazz.getMethod("getNamespace") } catch (_: Exception) { null }
        val setNs = try { clazz.getMethod("setNamespace", String::class.java) } catch (_: Exception) { null }
        val currentNs = try { getNs?.invoke(androidExt) as? String } catch (_: Exception) { null }
        if (currentNs.isNullOrBlank() && setNs != null) {
            // Derive a stable namespace from the project name
            val ns = "com.ironstronginitiative.${project.name.replace("-", "_")}"
            try { setNs.invoke(androidExt, ns) } catch (_: Exception) { /* ignore */ }
        }
    }
}
