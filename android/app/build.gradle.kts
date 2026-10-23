import java.util.Base64

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// flutter run/build --dart-define-from-file=secrets.json 으로 넣은 값(Gradle에는 base64로 넘어온다).
// 카카오 · 네이버 로그인 키를 Dart(lib/core/config/api_keys.dart)와 매니페스트가 같은 곳에서 읽게 한다
val dartDefines: Map<String, String> = (project.findProperty("dart-defines") as String?)
    ?.split(",")
    ?.mapNotNull { runCatching { String(Base64.getDecoder().decode(it)) }.getOrNull() }
    ?.filter { it.contains("=") }
    ?.associate { it.substringBefore("=") to it.substringAfter("=") }
    ?: emptyMap()

android {
    namespace = "com.gyeomsagyeomsa.app"
    compileSdk = flutter.compileSdkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.gyeomsagyeomsa.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = maxOf(flutter.minSdkVersion, 23)
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // 비어 있으면 앱이 로그인 버튼을 그리지 않는다(SocialLogin.kakaoReady · naverReady)
        manifestPlaceholders["kakaoNativeKey"] = dartDefines["KAKAO_NATIVE_KEY"] ?: ""
        manifestPlaceholders["naverLoginId"] = dartDefines["NAVER_LOGIN_ID"] ?: ""
        manifestPlaceholders["naverLoginSecret"] = dartDefines["NAVER_LOGIN_SECRET"] ?: ""
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
