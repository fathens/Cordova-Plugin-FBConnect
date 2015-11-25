#!/bin/bash

cat <<EOF > build.gradle
buildscript {
    repositories {
        mavenCentral()
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:1.+'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:1.+"
    }
}
apply plugin: 'com.android.application'
apply plugin: 'kotlin-android'

repositories {
    mavenCentral()
}

apply from: "plugin.gradle"

dependencies {
    compile "org.jetbrains.kotlin:kotlin-stdlib:1.+"
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
EOF

echo "sdk.dir=$ANDROID_HOME" > local.properties
git clone -b 4.1.x https://github.com/apache/cordova-android.git tmp && mv tmp/framework/src .cordova && rm -rf tmp

gradle wrapper --gradle-version 2.7

echo "Generating project done"
echo "Open by AndroidStudio. Thank you."
