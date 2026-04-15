# 10 or Equal - React Native

React Native version of **10 or Equal - Attention Game**.

The game shows a grid of numbers. Select two active cells to remove them when:

- the numbers are equal, or
- the numbers add up to 10.

Cells can be matched when they are visible neighbors horizontally or vertically, skipping removed cells in that line. The **Продолжить** button appends the remaining active numbers to the end of the board so the game can continue.

## Requirements

- Node.js 18 or newer
- npm
- Android Studio with Android SDK installed
- Android emulator or a physical Android device with USB debugging enabled
- JDK 17 for Android builds

This project uses React Native `0.78.2`.

## Install Dependencies

From this directory:

```sh
cd /home/vyacheslav/dev/10-or-equal/rn
npm install
```

## Run On Android

Start an emulator from Android Studio, or connect a physical Android device. Check that Android Debug Bridge can see it:

```sh
adb devices
```

Then run the app:

```sh
cd /home/vyacheslav/dev/10-or-equal/rn
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
npm run android
```

`npm run android` builds the debug APK, installs it on the connected emulator/device, starts Metro if needed, and launches the app.

If Metro is already running, that is fine. The command may print:

```text
info A dev server is already running for this project on port 8081.
```

## Useful Commands

Start Metro manually:

```sh
npm start
```

Build the Android debug APK without installing it:

```sh
cd android
JAVA_HOME=/usr/lib/jvm/java-17-openjdk ./gradlew assembleDebug
```

The generated debug APK is written to:

```text
android/app/build/outputs/apk/debug/app-debug.apk
```

Run tests:

```sh
npm test
```

Run lint:

```sh
npm run lint
```

## Troubleshooting

### Android project not found

If `npm run android` prints:

```text
error Android project not found.
```

make sure the `android/` directory exists in this React Native project:

```sh
ls android
```

The Android native project is required by `react-native run-android`.

### Unsupported class file major version 69

This means the build is using a Java version that is too new for the current Gradle/React Native setup. On this machine, OpenJDK 25 triggers this error.

Use JDK 17:

```sh
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
npm run android
```

Check the active Java version:

```sh
java -version
```

### NDK source.properties is missing

If Gradle reports an error like:

```text
NDK at ... did not have a source.properties file
```

the selected NDK install is incomplete or corrupted. This project is configured to use:

```text
28.0.12433566
```

If that version is missing, install it from Android Studio:

1. Open **Settings**.
2. Go to **Languages & Frameworks** -> **Android SDK**.
3. Open **SDK Tools**.
4. Enable **Show Package Details**.
5. Install **NDK (Side by side) 28.0.12433566**.

### No devices found

If the build succeeds but the app does not install, check connected devices:

```sh
adb devices
```

You should see an emulator or device in the `device` state. If the list is empty, start an emulator in Android Studio or reconnect the physical device and allow USB debugging.

### Metro cache issues

If the app launches but JavaScript changes are not picked up, restart Metro with a clean cache:

```sh
npm start -- --reset-cache
```

Then run Android again in another terminal:

```sh
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
npm run android
```
