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

// The Flutter integration_test plugin currently requests androidx.test:runner
// with a dynamic 1.2+ selector. Keep Android builds deterministic when Maven
// metadata is unavailable (for example, on an offline/filtered network).
subprojects {
    configurations.configureEach {
        resolutionStrategy.eachDependency {
            if (requested.group == "androidx.test" &&
                requested.name == "runner" &&
                requested.version == "1.2+") {
                useVersion("1.3.0")
                because("avoid dynamic integration_test metadata resolution")
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
