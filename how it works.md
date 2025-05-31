```mermaid
flowchart LR
  subgraph Remote_Device["Remote Device (Moonlight Client)"]
    C1[Controller Input]
    C2[Moonlight App]
  end

  subgraph PC["Windows PC (Sunshine Host)"]
    D1[Sunshine]
    D2[ffmpeg/ffplay]
    D3[ViGEmBus]
    D4[Python Scripts]
    D5[HDMI Capture Card]
  end

  subgraph Console["Game Console"]
    E1[HDMI Output]
    E2[USB Port]
  end

  subgraph Pico["Raspberry Pi Pico<br/>GP2040-CE"]
    F1[USB Emulation]
    F2[Network Receiver]
  end

  %% Data Flows
  C1 -- "User presses button" --> C2
  C2 -- "Sends input & receives video stream" --> D1
  D1 -- "Streams video/audio" --> C2
  D1 -- "Launches ffplay for preview" --> D2
  D1 -- "Receives controller input" --> D3
  D3 -- "Virtual Controller Events" --> D4
  D4 -- "Forwards input over network" --> F2
  D5 -- "Captures HDMI from Console" --> D2
  D2 -- "Preview to user (optional)" --> D1
  F2 -- "Emulates controller signals over USB" --> F1
  F1 -- "Acts as real controller" --> E2
  E1 -- "HDMI Out" --> D5

  %% Hardware Connections
  E2 -. "USB Cable" .-> F1
  E1 -. "HDMI Cable" .-> D5

  %% Annotations
  classDef box fill:#e3e3ff,stroke:#222,stroke-width:2px;
  class Remote_Device,PC,Console,Pico box;
```
**Big Diagram: Console-Stream Architecture**

- **Blue boxes** = Hardware/Software units
- **Solid arrows** = Data flow
- **Dashed arrows** = Physical connections (cables)

### Summary:
- Your controller input and display are on the remote device (Moonlight).
- Video is streamed from the console to PC (via HDMI capture card), then to Moonlight.
- Controller input from Moonlight is sent back to the PC, then via Python scripts over the network to the Pico.
- The Pico emulates a real controller, sending input to the console via USB.
