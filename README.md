[Blade](https://github.com/javan/blade) plugin for [Sauce Labs](https://saucelabs.com/)

## Configuration

### Authenticate with Sauce Labs

Set the `SAUCE_USERNAME` and `SAUCE_ACCESS_KEY` environment variables to authenticate with Sauce Labs.

All CI tools provide a way to set environment variables for a test run. For non-CI test runs, set the environment variables in your shell or in your test runner script.

### Pick the browsers to run against

Rather than exhaustively list every permutation of devices, operating systems,
and browsers, we use a shorthand to match all the platforms we target.

Full example:
```yaml
plugins:
  sauce_labs:
    browsers:
      # Internet Explorer 11 on every device and operating system it supports.
      IE: 11

      # Latest two Chrome releases on all Mac and Windows platforms:
      Google Chrome:
        os: Mac, Windows
        version: -2

      # Latest two Firefox releases on every platform:
      Firefox:
        version: -2

      # Latest Safari release on every Mac platform (OS X 10.x):
      Safari:
        platform: Mac
        version: -1

      # Latest two Edge releases on every platform:
      Microsoft Edge:
        version: -2

      # Specific iOS Mobile Safari versions:
      iPhone:
        version: [9.2, 8.4]

      # Mobile-specific browser:
      Motorola Droid 4 Emulator:
        version: [5.1, 4.4]
```

See Sauce Labs' [Platform Configurator](https://wiki.saucelabs.com/display/DOCS/Platform+Configurator) for an exhaustive list of supported devices, operating systems, and browsers.
