# ESP32 Arduino Lib Builder

This repository is a FORK of the espressif/esp32-arduino-lib-builder and contains the scripts that produce the libraries included with esp32-arduino.

It contains modifications in the manner to ... 
* Get info in Terminal to see, what is going on, **without getting floated** with messages.
* See **what scripts** are called & what **files** & **Folder** they generate (build.sh).
* Get it running on macOS.
* Add **new arguments** to come up with more easy to understand the (build.sh)-output. 
* Integates **PlatformIO output**. Thanks! to: [Jason2888](https://github.com/Jason2866/esp32-arduino-lib-builder)

## To used with macOS...
### It is tested with:
* macOS Moneytary running on (Intel)
* macOS Ventura   running on (ARM/M1)

### Install needed tools on macOS:
* Install [Xcode](https://www.google.com/url?sa=t&source=web&rct=j&opi=89978449&url=https://apps.apple.com/us/app/xcode/id497799835%3Fmt%3D12&ved=2ahUKEwjwn4vkzqiGAxUahf0HHTb6CXQQFnoECBMQAQ&usg=AOvVaw2fEvMbfRtGhB4SPHYB54NX) as it provide the needed ***build*** cababilities
* This tools are already installed with macOS or XCode: **git**, ***flex***,  ***bison***, ***gperf*** <br/>
  - You and simply check if installed example: *git --version*
* Install [Phython for macOS](https://www.python.org/downloads)
  - Don't forget to update the Certificates with 'Install Certificates.command' after installation!
* Install with [Homebrew](https://brew.sh)
  ```bash 
  # See what already is installed 
  brew list # All
  brew list wget # Check a certain package
  # Install what is missing - ONE BY ONE!!! NOT in one line!! like here.. 
  brew install wget, curl, openssl, ncurses, cmake, ninja, ccache, jq, gsed, gawk, dfu-util
  ```

* Install Python-Modules with ***pip***
    ```bash
    sudo pip install --upgrade pip
    ```
    New module is required for esp-idf
    ```bash
    sudo pip install pyclang
    ```


### Run build on macOS

```bash
git clone https://github.com/twischi/esp32-arduino-lib-builder && cd esp32-arduino-lib-builder
./build.sh
```

You will be ask with start of build.sh, if you want to run with default Parameter >> Then this [file](https://github.com/twischi/esp32-arduino-lib-builder/blob/master/setMyParameters.sh) is used. 


### Run build with save a log-file

  ```bash
  git clone https://github.com/twischi/esp32-arduino-lib-builder && cd esp32-arduino-lib-builder
  ./myBuild_with_log.sh
  ```

### Clone and open in VSCode

  ```bash
  git clone https://github.com/twischi/esp32-arduino-lib-builder && cd esp32-arduino-lib-builder
  code. 
  ```

## See also the original documentation by espressif:

#### [ Documetation at 'espressif/esp32-arduino-lib-builder'](https://github.com/espressif/esp32-arduino-lib-builder)