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
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// =====================================================================
// MASTER BLOCK: RESOLVES DUPLICATE NAMESPACE + COMPILESDK FOR ALL SUBPROJECTS
// =====================================================================
subprojects {
    // 1. Exclude conflicting Agora AAR that causes duplicate io.agora.rtc namespace
    configurations.all {
        resolutionStrategy {
            exclude(group = "io.agora.rtc", module = "agora-special-full")
        }
    }

    // 2. Force compileSdk 36 on ALL library subprojects (fixes agora_rtc_engine android-31 issue)
    val configureProjectOverrides = Action<Project> {
        if (plugins.hasPlugin("com.android.application") || plugins.hasPlugin("com.android.library")) {
            extensions.findByType(com.android.build.gradle.BaseExtension::class.java)?.apply {
                compileSdkVersion(36)
                defaultConfig {
                    targetSdkVersion(36)
                }
            }
        }
    }

    if (project.state.executed) {
        configureProjectOverrides.execute(project)
    } else {
        project.afterEvaluate { configureProjectOverrides.execute(project) }
    }
}