#!/bin/bash

cat <<EOF > build.gradle
buildscript {
    repositories {
        mavenCentral()
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:1.3.1'
        classpath 'org.jetbrains.kotlin:kotlin-gradle-plugin:0.14.449'
    }
}
apply plugin: 'com.android.application'
apply plugin: 'kotlin-android'

repositories {
    mavenCentral()
}
dependencies {
	compile 'org.jetbrains.kotlin:kotlin-stdlib:0.14.449'
}

android {
    compileSdkVersion 'android-21'
    buildToolsVersion '22.0.1'
    sourceSets {
        main.java {
            srcDirs += '.cordova'
            srcDirs += 'src/main/kotlin'
        }
    }
}

task cordova(type: Exec) {
    executable "sh"
    args '-c', 'git clone -b 4.1.x https://github.com/apache/cordova-android.git tmp && mv tmp/framework/src .cordova && rm -rf tmp'
}
task localProperties << {
    file('local.properties').println java.lang.System.getenv()['ANDROID_HOME']
}
task prepare(dependsOn: [cordova, localProperties])
EOF

gradle wrapper --gradle-version 2.7
./gradlew prepare

echo "Generating project done"
echo "Open by AndroidStudio. Thank you."
