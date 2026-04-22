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
    val project = this
    project.layout.buildDirectory.value(newBuildDir.dir(project.name))
}

subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    val project = this
    
    // Configure Android projects as they are evaluated
    project.plugins.withType<com.android.build.gradle.BasePlugin> {
        val android = project.extensions.getByName("android") as com.android.build.gradle.BaseExtension
        
        // Fix missing namespace for AGP 8.0+
        if (android.namespace == null) {
            android.namespace = "com.example.${project.name.replace("-", "_")}"
        }
    }

    // Dynamically align Kotlin JVM target with the Java task's target compatibility
    // to resolve inconsistencies between different plugins (some use 1.8, some 11, some 17).
    project.tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        val javaTaskName = name.replace("Kotlin", "JavaWithJavac")
        val javaTask = project.tasks.withType<JavaCompile>().findByName(javaTaskName)
        if (javaTask != null) {
            compilerOptions {
                val target = javaTask.targetCompatibility
                when {
                    target.contains("17") -> jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
                    target.contains("11") -> jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11)
                    target.contains("21") -> jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_21)
                    else -> jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_1_8)
                }
            }
        }
    }

    // Manifest stripping hack for AGP 8.0+ compatibility with old plugins
    fun configureManifestStripping() {
        if (project.plugins.hasPlugin("com.android.library") || project.plugins.hasPlugin("com.android.application")) {
            project.tasks.matching { it.name.contains("process") && it.name.contains("Manifest") }.configureEach {
                doFirst {
                    val manifestFile = project.file("src/main/AndroidManifest.xml")
                    if (manifestFile.exists()) {
                        val content = manifestFile.readText()
                        if (content.contains("package=")) {
                            val updatedContent = content.replace(Regex("""package="[^"]*""""), "")
                            manifestFile.writeText(updatedContent)
                        }
                    }
                }
            }
        }
    }

    if (project.state.executed) {
        configureManifestStripping()
    } else {
        project.afterEvaluate { configureManifestStripping() }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
