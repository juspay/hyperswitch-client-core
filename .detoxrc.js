/** @type {Detox.DetoxConfig} */
module.exports = {
  testRunner: {
    args: {
      $0: 'jest',
      config: 'detox-tests/e2e/jest.config.js',
    },
    jest: {
      setupTimeout: 120000,
    },
  },
  apps: {
    'ios.debug': {
      type: 'ios.app',
      binaryPath:
        'ios/build/Build/Products/Debug-iphonesimulator/HyperSwitch.app',
      build:
        'xcodebuild -workspace ios/hyperswitch.xcworkspace -scheme hyperswitch -configuration Debug -sdk iphonesimulator -derivedDataPath ios/build',
    },
    'ios.release': {
      type: 'ios.app',
      binaryPath:
        'ios/build/Build/Products/Release-iphonesimulator/HyperSwitch.app',
      build:
        'xcodebuild -workspace ios/hyperswitch.xcworkspace -scheme hyperswitch -configuration Release -sdk iphonesimulator -derivedDataPath ios/build',
    },
    'android.debug': {
      type: 'android.apk',
      binaryPath: 'android/demo-app/build/outputs/apk/debug/demo-app-debug.apk',
      testBinaryPath:
        'android/demo-app/build/outputs/apk/androidTest/debug/demo-app-debug-androidTest.apk',
      build:
        'cd android ; ./gradlew assembleDebug assembleAndroidTest -DtestBuildType=debug ; cd -',
      reversePorts: [8081],
    },
    'android.release': {
      type: 'android.apk',
      binaryPath: 'android/app/build/outputs/apk/release/app-release.apk',
      build:
        'cd android && ./gradlew assembleRelease assembleAndroidTest -DtestBuildType=release',
    },
  },
  devices: {
    simulator: {
      type: 'ios.simulator',
      device: {
        type: 'iPhone 16 Pro Max',
      },
    },
    attached: {
      type: 'android.attached',
      device: {
        adbName: '.*',
      },
    },
    emulator: {
      type: 'android.emulator',
      device: {
        avdName: 'Medium_Phone',
      },
      headless: false,
      gpuMode: 'auto',
      bootArgs: '-no-snapshot -no-snapshot-load -no-snapshot-save -gpu swiftshader_indirect -no-audio -no-boot-anim',
    },
    ciEmulator: {
      type: 'android.emulator',
      device: {
        avdName: 'test',
      },
      headless: true,
      gpuMode: 'swiftshader_indirect',
      bootArgs: '-no-window -no-snapshot -no-snapshot-load -no-snapshot-save -no-audio -no-boot-anim -gpu swiftshader_indirect',
      utilBinaryPaths: ['platform-tools/adb'],
      readonly: true,
      forceAdbInstall: true,
    },
  },
  configurations: {
    'ios.sim.debug': {
      device: 'simulator',
      app: 'ios.debug',
    },
    'ios.sim.release': {
      device: 'simulator',
      app: 'ios.release',
    },
    'android.att.debug': {
      device: 'attached',
      app: 'android.debug',
    },
    'android.att.release': {
      device: 'attached',
      app: 'android.release',
    },
    'android.emu.debug': {
      device: 'emulator',
      app: 'android.debug',
    },
    'android.emu.ci.debug': {
      device: 'ciEmulator',
      app: 'android.debug',
      behavior: {
        init: {
          launchApp: false,
        },
        launchApp: 'auto',
        cleanup: {
          shutdownDevice: false,
        },
      },
      session: {
        server: 'ws://localhost:8099',
        sessionId: 'test',
        autoStart: true,
      },
      artifacts: {
        rootDir: './artifacts',
        plugins: {
          log: { enabled: true },
          screenshot: {
            enabled: true,
            shouldTakeAutomaticSnapshots: true,
            keepOnlyFailedTestsArtifacts: false,
            takeWhen: {
              testStart: true,
              testDone: true,
              appNotReady: true,
              beforeEach: true,
              afterEach: true,
            },
          },
          video: {
            enabled: true,
            keepOnlyFailedTestsArtifacts: false,
          },
        },
      },
    },
    'android.emu.release': {
      device: 'emulator',
      app: 'android.release',
    },
  },
};
