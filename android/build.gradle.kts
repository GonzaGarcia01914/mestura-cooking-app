import com.android.build.api.dsl.LibraryExtension
import org.gradle.api.plugins.JavaPluginExtension
import org.gradle.jvm.toolchain.JavaLanguageVersion

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// 🚫 Eliminado el bloque buildscript/classpath (opción 1 usa Plugins DSL)

val newBuildDir: Directory =
    rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

// === Solo tocar librerías (plugins) y, si existieran, proyectos Java puros ===
subprojects {
    // Plugins Android (com.android.library): forzamos Java 17
    plugins.withId("com.android.library") {
        extensions.configure<LibraryExtension>("android") {
            compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
        }
    }

    // Proyectos Java puros (no Android): usar toolchain 17
    plugins.withId("java") {
        the<JavaPluginExtension>().toolchain.languageVersion.set(JavaLanguageVersion.of(17))
    }
    plugins.withId("java-library") {
        the<JavaPluginExtension>().toolchain.languageVersion.set(JavaLanguageVersion.of(17))
    }

    // ⚠️ No reconfigurar aquí tareas JavaCompile ni el módulo :app
    // (evitamos "sourceCompatibility has been finalized")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
