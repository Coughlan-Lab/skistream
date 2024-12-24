# SKISTREAM

This project implements a client-server architecture for streaming data, where the client is an iOS app written in Swift, and the server is implemented in Python. The communication between the client and server is done over TCP/UDP sockets.

The client supports configurations for data streaming and has the potential for integration with Augmented Reality (AR) features. The server can be started using either TCP or UDP via simple shell scripts.

## Table of Contents
- [Requirements](#requirements)
- [Setup](#setup)
  - [Server Setup](#server-setup)
  - [iOS Client Setup](#ios-client-setup)
- [Usage](#usage)
  - [Server Usage](#server-usage)
  - [iOS Client Usage](#ios-client-usage)
- [Implementation](#implementation)
- [License](#license)

---

## Requirements

### Server-Side (Python)
- Python 3.x
- Required Python Libraries:
  - `socket`
  - Any other required libraries for server logic

### Client-Side (iOS)
- Xcode 12.0 or later
- Swift 5.0 or later
- ARKit (if AR integration is enabled)
- CocoaPods (or Swift Package Manager for dependency management, if needed)

---

## Setup

**Clone the repository**:
```bash
git clone <repo_url>
cd <repo_name>
```

---

### Server Setup
**Run the server script**:
    
```cd skistream_PY```

Choose whether to use TCP or UDP. You can start the server by running one of the following scripts:

- For **TCP**:
    ```bash
    ./tcp.sh
    ```
- For **UDP**:
    ```bash
    ./udp.sh
    ```

These scripts will launch the server and listen for incoming client connections on the configured IP address and port.

**Check server logs**: The server will log incoming data and connection status to the terminal.

---

### iOS Client Setup

```cd skistream_IOS```

**Open the project** ```skistream.xcworkspace``` in Xcode.

**Build and run the app**: Select your target device and run the app.

---

## Usage

### Server Usage

1. **Start the Server**: After running the appropriate shell script (`tcp.sh` or `udp.sh`), the server will start listening for incoming connections. Make sure to note the IP address and port where the server is listening, as you will need to provide this information on the iOS client.

### iOS Client Usage

1. **Open the iOS App**: Launch the app on your device or simulator.

2. **Configuration Page**:
    - On the configuration page, set up the parameters for the data stream (e.g., resolution, data format).
    - If applicable, configure any AR-related options (e.g., AR scene setup, camera input, etc.).

3. **Connect to Server**:
    - Navigate to the **Socket Connection** page.
    - Enter the IP address and port of the server that was started previously.
    - Tap **Connect** to establish the socket connection between the iOS client and Python server.

4. **Start Streaming**:
    - Go to the **Stream Data** page to start the data stream.
    - The app will begin receiving and sending data to the server via the established socket connection.
    - If AR is enabled, you can visualize the data in the AR interface.

---

## Implementation

### general structure

### Data Priorities

Each piece of data in the system has an associated **priority**, which governs its treatment in the system’s buffer. The priority of a data type is represented by a tuple: `(base_ms, increment_ms)`, where:
- **base_ms**: The base transmission delay (in milliseconds) for the data type. This is the ideal delay for the data to be transmitted.
- **increment_ms**: The increment in milliseconds applied to the base delay if the data is not pushed (transmitted) on time.

#### Priority Mechanism:
- When data is pushed into the buffer, it is checked to ensure that both **buffer space** and **transmission delay** are sufficient to accommodate the data.
- If the data can be added to the buffer, the **priority** of the data type is reset to its **base_ms** value, and the transmission occurs immediately.
- If the data cannot be pushed (because there is insufficient buffer space or the transmission delay exceeds the allowed priority), the priority of the data type is incremented by the **increment_ms** value.

#### Example:
Suppose we have a data type `video_frame` with a priority of `(base_ms=50, increment_ms=10)`:
- The first time `video_frame` is pushed, its delay will be 50ms (base priority).
- If the buffer is full or there’s not enough time to transmit the frame within the given delay, the next time `video_frame` tries to push data, its priority will be increased to 60ms (base + increment), and this process will continue until it is successfully transmitted.

This priority-based mechanism ensures that time-sensitive data (such as real-time video frames or sensor data) is prioritized and pushed before less urgent data.

### Enqueueing Policy (Last-Only)

In addition to the priority-based buffer management, there is an **Enqueueing Policy** applied to each data type, **Last-Only** and **Enqueue**.

The **Last-Only** policy ensures that only the most recent data of a given type is kept in the buffer when multiple pieces of the same data type are enqueued.
- **Last-Only Rule**: If a new data item of a specific type is enqueued while an older one is still present, the system will discard the older data and only retain the latest piece of data for that type in the buffer.

The **Enqueue** policy ensures that all data of a given type is kept in the buffer when multiple pieces of the same data type are enqueued.
- **Enqueue Rule**: If a new data item of a specific type is enqueued while an older one is still present, the system will kept both.

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.