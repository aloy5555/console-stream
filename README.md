[ Console ]───[ ESP32 ]<──────────────┐
                                       │ (serial or Wi-Fi)
                                  [ Node Server ]
                                ┌────────┴────────┐
                                │    WebSocket    │
                                │    Express.js   │
                                └────────┬────────┘
                                         │
          ┌──────────────────────────────┴───────────────┐
          │ [ Web Client UI ]                            │
          │ - Shows live stream                          │
          │ - Sends controller input                     │
          └──────────────────────────────────────────────┘
