# J4ino - Fully Embedded Arduino CLI for Java

🚀 **Zero-dependency Arduino CLI integration for Java!**

J4ino is a fully embedded JNI library that includes arduino-cli binaries for all major platforms. No external installation required - just add the JAR and go!

## Features

- ✅ **Fully Embedded** - arduino-cli binaries included for all platforms
- ✅ **Zero Installation** - No need to install arduino-cli separately
- ✅ **Cross-Platform** - Supports Linux, macOS, and Windows (x86_64 & ARM64)
- ✅ **High-Level API** - Easy-to-use Java wrapper
- ✅ **Low-Level Access** - Direct JNI calls available if needed
- ✅ **Automatic Extraction** - Binaries extracted to temp directory on first use

## Supported Platforms

- **Linux**: x86_64, ARM64
- **macOS**: x86_64, ARM64 (Apple Silicon)
- **Windows**: x86_64

## Quick Start

### Basic Usage

```java
import com.anode.arduino.ArduinoCLI;

public class MyArduinoApp {
    public static void main(String[] args) {
        // Create instance - automatically extracts embedded arduino-cli
        ArduinoCLI arduino = new ArduinoCLI();

        // Get version
        System.out.println(arduino.version());

        // List connected boards
        System.out.println(arduino.boardList());

        // Update package index
        arduino.coreUpdateIndex();

        // Install Arduino AVR core
        arduino.coreInstall("arduino:avr");

        // Compile a sketch
        arduino.compile("/path/to/sketch", "arduino:avr:uno");

        // Upload to board
        arduino.upload("/path/to/sketch", "arduino:avr:uno", "/dev/ttyACM0");
    }
}
```

## API Reference

### ArduinoCLI Class

High-level wrapper with convenient methods:

#### Board Management
- `String boardList()` - List connected boards
- `String boardListAll()` - List all available boards
- `String boardSearch(String query)` - Search for boards
- `String boardDetails(String fqbn)` - Get board details

#### Core Management
- `String coreInstall(String core)` - Install board core (e.g., "arduino:avr")
- `String coreList()` - List installed cores
- `String coreUpdateIndex()` - Update package index

#### Library Management
- `String libSearch(String query)` - Search for libraries
- `String libInstall(String library)` - Install library
- `String libList()` - List installed libraries

#### Sketch Operations
- `String compile(String sketchPath, String fqbn)` - Compile sketch
- `String upload(String sketchPath, String fqbn, String port)` - Upload sketch
- `String compileAndUpload(String sketchPath, String fqbn, String port)` - Compile and upload
- `String sketchNew(String name)` - Create new sketch

#### Utility
- `String version()` - Get arduino-cli version
- `String config()` - Get configuration
- `String exec(String command)` - Execute custom command
- `String getArduinoCliPath()` - Get path to extracted binary

## Building from Source

### Prerequisites

- Java 11 or higher
- Apache Maven 3.6+ (recommended) or Make
- GCC compiler (or equivalent)

### Quick Build with Maven (Recommended)

```bash
# Build everything with one command
mvn clean install

# Run the JAR
java -jar target/j4ino-1.0-SNAPSHOT.jar
```

Maven automatically:
- Downloads arduino-cli binaries (if needed)
- Builds native JNI library
- Compiles Java code
- Packages everything into a JAR

See [MAVEN.md](MAVEN.md) for complete Maven build guide.

### Build Profiles

```bash
# Build for current platform (default)
mvn clean install

# Build for all platforms (requires cross-compilers)
mvn clean install -P all-platforms

# Build all platforms with Docker (easiest)
mvn clean install -P docker-build

# Skip native build (use pre-built libraries)
mvn clean install -P skip-native
```

### Alternative: Makefile

```bash
# Build for your current platform
make native && make java && make jar

# Build all platforms
make all-platforms

# Show all options
make help
```

See [BUILD.md](BUILD.md) for detailed Makefile and cross-compilation guide.


## Project Structure

```
J4ino/
├── src/
│   └── main/
│       ├── java/
│       │   ├── com/anode/arduino/
│       │   │   ├── ArduinoCLI.java              # High-level API
│       │   │   └── Example.java                 # Usage example
│       │   └── com/anode/arduino/jni/
│       │       ├── ArduinoCLINative.java        # JNI interface
│       │       └── NativeLibraryLoader.java     # Resource extraction
│       ├── C/
│       │   ├── arduino_cli_wrapper.c            # Native implementation
│       │   └── com_anode_arduino_jni_ArduinoCLINative.h
│       └── resources/
│           ├── arduino-cli/                      # Embedded arduino-cli
│           │   ├── linux-x86_64/
│           │   ├── linux-aarch64/
│           │   ├── macos-x86_64/
│           │   ├── macos-aarch64/
│           │   └── windows-x86_64/
│           └── native/                           # JNI libraries
│               └── linux-x86_64/
├── build-native.sh                               # Build JNI library
├── download-arduino-cli.sh                       # Download binaries
└── pom.xml                                       # Maven configuration
```

## How It Works

1. **Embedded Binaries**: arduino-cli binaries for all platforms are bundled in `src/main/resources/arduino-cli/`

2. **Automatic Extraction**: On first use, `NativeLibraryLoader` detects your platform and extracts:
   - The appropriate arduino-cli binary
   - The native JNI wrapper library

3. **Temporary Storage**: Binaries are extracted to a temporary directory (`/tmp/j4ino_*`) with automatic cleanup

4. **JNI Execution**: The native wrapper uses `popen()` to execute arduino-cli commands and capture output

## Advanced Usage

### Low-Level JNI Access

If you need direct control:

```java
import com.anode.arduino.jni.ArduinoCLINative;

// Execute raw command
String output = ArduinoCLINative.exec("/path/to/arduino-cli version");
```

### Custom arduino-cli Path

By default, the embedded binary is used. To use a custom arduino-cli:

```java
String output = ArduinoCLINative.exec("/custom/path/arduino-cli board list");
```

## Examples

### Complete Workflow

```java
ArduinoCLI arduino = new ArduinoCLI();

// Setup
arduino.coreUpdateIndex();
arduino.coreInstall("arduino:avr");
arduino.libInstall("Servo");

// Create and compile sketch
arduino.sketchNew("MyProject");
arduino.compile("MyProject", "arduino:avr:uno");

// Find board and upload
String boards = arduino.boardList();
arduino.upload("MyProject", "arduino:avr:uno", "/dev/ttyACM0");
```

### Board Discovery

```java
ArduinoCLI arduino = new ArduinoCLI();

// Search for ESP32 boards
System.out.println(arduino.boardSearch("esp32"));

// Get details about a specific board
System.out.println(arduino.boardDetails("arduino:avr:uno"));
```

## Troubleshooting

### "Resource not found" error
- Ensure `src/main/resources/` is in your classpath
- Check that arduino-cli binaries were downloaded correctly
- Run `./download-arduino-cli.sh` to re-download

### Permission denied (Linux/macOS)
- The library automatically sets execute permissions
- If issues persist, manually: `chmod +x /tmp/j4ino_*/arduino-cli`

### Platform not supported
- Check your OS and architecture: `uname -s` and `uname -m`
- The library supports: Linux (x64, arm64), macOS (x64, arm64), Windows (x64)

## Version Information

- **J4ino**: 1.0-SNAPSHOT
- **Embedded arduino-cli**: v1.3.1
- **Minimum Java**: 11

## Building a JAR

To create a distributable JAR with all resources:

```bash
# Compile
javac -d target/classes src/main/java/com/anode/arduino/**/*.java src/main/java/com/anode/arduino/jni/*.java

# Copy resources
cp -r src/main/resources/* target/classes/

# Create JAR
jar cvf j4ino-1.0.jar -C target/classes .
```

Usage:
```bash
java -cp j4ino-1.0.jar com.anode.arduino.Example
```

## Contributing

Contributions welcome! Areas for improvement:
- Add more high-level API methods
- Better error handling
- Progress callbacks for long operations
- JSON parsing for structured output

## License

MIT License - See LICENSE file for details

## Credits

- **arduino-cli**: Arduino Team ([https://github.com/arduino/arduino-cli](https://github.com/arduino/arduino-cli))
- **J4ino**: Built with JNI for seamless Java integration

---

**Made with ❤️ for the Arduino and Java communities**
