# console-stream

**console-stream** is a fully automated remote play framework for Nintendo Switch, PlayStation 4, and PlayStation 5 using a Raspberry Pi Pico running [GP2040-CE](https://gp2040-ce.info/), an HDMI capture card, and open-source streaming tools (Sunshine + Moonlight).  
With these scripts, you can stream your console to any device and send controller input from anywhere back to your console—no special hardware mods required!

---

## Features

- **One-click automation:** Setup scripts for Windows automate all configuration steps.
- **Multi-console support:** Choose between Switch, PS4, or PS5 GP2040-CE emulation.
- **Seamless controller passthrough:** Use your controller on any Moonlight client (PC, Android, iOS, etc.) and control your console remotely.
- **Open source:** All scripts are fully editable and extensible.

---

## How It Works

1. **Video/Audio**: Your console’s HDMI output is captured and streamed via Sunshine to any Moonlight client.
2. **Controller Input**: Your controller input on Moonlight is sent to the PC, then forwarded over the network to the Pico, which emulates a real controller for your console via USB.

---

## Requirements

- **Raspberry Pi Pico** running [GP2040-CE](https://gp2040-ce.info/) (with Switch, PS4, or PS5 firmware)
- **Windows PC** (Sunshine host) with:
  - HDMI capture card (USB, compatible with ffplay)
  - [Sunshine](https://sunshineapp.dev/)
  - [ViGEmBus](https://vigembus.github.io/) (for virtual controller)
  - [Python 3](https://www.python.org/downloads/) (`inputs` and `requests` modules)
  - [ffmpeg/ffplay](https://www.gyan.dev/ffmpeg/builds/) (for video preview)
- **Moonlight client** (on your remote device)
- **Controller** connected to your Moonlight client

---

## Setup

### 1. Flash GP2040-CE on your Pico

- Download the correct firmware for your console from [GP2040-CE downloads](https://gp2040-ce.info/download/).
- Hold BOOTSEL, plug in the Pico, drag-and-drop the UF2 file.

### 2. Hardware Connections

- **Pico** → Console USB port
- **Console HDMI Out** → HDMI Capture Card In
- **Capture Card USB** → Windows PC

### 3. Prepare Windows PC

- Install [Sunshine](https://sunshineapp.dev/)
- Install [ViGEmBus](https://vigembus.github.io/)
- Install [Python 3](https://www.python.org/downloads/) and run:
  ```sh
  pip install inputs requests
  ```
- [Download](https://www.gyan.dev/ffmpeg/builds/) and add ffplay to your PATH.

### 4. Clone this Repository

```sh
git clone https://github.com/aloy5555/console-stream.git
cd console-stream
```

### 5. Edit the Batch File

- Open `gp2040ce_windows_automation.bat` in a text editor.
- Set your Pico's IP address and HDMI capture device name near the top:
  ```batch
  set PICO_IP=192.168.1.100
  set HDMI_DEVICE=video="YOUR HDMI DEVICE NAME HERE"
  ```
- (Find your device name by running `ffplay -list_devices true -f dshow -i dummy`)

### 6. Configure Sunshine App

- Open the Sunshine web UI ([http://localhost:47990/](http://localhost:47990/)).
- Add a new application:
  - **Name:** Console HDMI
  - **Command:**  
    ```
    ffplay -fflags nobuffer -flags low_delay -framedrop -i video="YOUR HDMI DEVICE NAME HERE" -window_title "ConsoleStream"
    ```

### 7. Run the Automation Script

- Double-click `gp2040ce_windows_automation.bat`
- Choose which console to emulate (Switch, PS4, PS5)
- When prompted, leave all windows open

### 8. Connect via Moonlight

- Use Moonlight on your chosen device
- Enable “Virtual Gamepad” in Moonlight settings
- Launch the **Console HDMI** app
- Use your controller—input will be sent to your console via the Pico

---

## Licensing

This project is licensed under a **custom Non-Commercial, Attribution-Required License**.

**Key points:**
- No commercial use allowed.
- If you use any part of this project in your own code or in a public project, you must provide clear attribution and a link to this repository.
- For commercial use, contact the author.

See [LICENSE](LICENSE) for the full license text.

---

## Credits

- [GP2040-CE](https://gp2040-ce.info/) by the OpenStickCommunity
- [Sunshine](https://sunshineapp.dev/) and [Moonlight](https://moonlight-stream.org/)
- [ViGEmBus](https://vigembus.github.io/)

---

**Enjoy true remote play on your console—no mods required!**
