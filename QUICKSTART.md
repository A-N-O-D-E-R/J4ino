# J4ino Quick Start Guide

Get started with J4ino in under 5 minutes!

## Prerequisites

- Java 11 or higher installed
- That's it! No arduino-cli installation needed!

## Option 1: Use Pre-built JAR (Easiest)

If you have a pre-built `j4ino-1.0.jar`:

```bash
# Run the example
java -cp j4ino-1.0.jar com.anode.arduino.Example

# Use in your project
java -cp j4ino-1.0.jar:your-app.jar com.your.MainClass
```

## Option 2: Build from Source

### Quick Build (One Command)

```bash
# Clone the repo
cd J4ino

# Build everything
./build-all.sh

# Run the example
java -cp target/classes com.anode.arduino.Example
```

### Manual Build

```bash
# 1. Download arduino-cli binaries
./download-arduino-cli.sh

# 2. Build native library
./build-native.sh

# 3. Compile Java
javac -d target/classes src/main/java/com/anode/arduino/**/*.java src/main/java/com/anode/arduino/jni/*.java

# 4. Copy resources
cp -r src/main/resources/* target/classes/

# 5. Run
java -cp target/classes com.anode.arduino.Example
```

## Your First Program

Create a file `MyArduino.java`:

```java
import com.anode.arduino.ArduinoCLI;

public class MyArduino {
    public static void main(String[] args) {
        // Create instance (automatic extraction)
        ArduinoCLI arduino = new ArduinoCLI();

        // Check version
        System.out.println(arduino.version());

        // List boards
        System.out.println(arduino.boardList());
    }
}
```

Compile and run:

```bash
# If using JAR
javac -cp j4ino-1.0.jar MyArduino.java
java -cp j4ino-1.0.jar:. MyArduino

# If using target/classes
javac -cp target/classes MyArduino.java
java -cp target/classes:. MyArduino
```

## Common Tasks

### Install Arduino Core

```java
ArduinoCLI arduino = new ArduinoCLI();

// Update index first
arduino.coreUpdateIndex();

// Install Arduino AVR boards
arduino.coreInstall("arduino:avr");

// Or ESP32
arduino.coreInstall("esp32:esp32");
```

### Compile a Sketch

```java
String result = arduino.compile(
    "/path/to/your/Blink",      // Sketch path
    "arduino:avr:uno"            // Board FQBN
);
System.out.println(result);
```

### Upload to Board

```java
// Find the port first
System.out.println(arduino.boardList());

// Upload
String result = arduino.upload(
    "/path/to/your/Blink",       // Sketch path
    "arduino:avr:uno",           // Board FQBN
    "/dev/ttyACM0"               // Port (or COM3 on Windows)
);
System.out.println(result);
```

### Search and Install Libraries

```java
// Search for a library
System.out.println(arduino.libSearch("Servo"));

// Install it
arduino.libInstall("Servo");

// List installed libraries
System.out.println(arduino.libList());
```

## Complete Workflow Example

```java
import com.anode.arduino.ArduinoCLI;

public class CompleteWorkflow {
    public static void main(String[] args) {
        ArduinoCLI arduino = new ArduinoCLI();

        System.out.println("Setting up Arduino environment...");

        // 1. Update package index
        arduino.coreUpdateIndex();

        // 2. Install Arduino AVR core
        arduino.coreInstall("arduino:avr");

        // 3. Install Servo library
        arduino.libInstall("Servo");

        // 4. Create new sketch
        arduino.sketchNew("MyRobot");

        // 5. Compile sketch (after you edit it)
        System.out.println("Compiling...");
        String compileResult = arduino.compile("MyRobot", "arduino:avr:uno");
        System.out.println(compileResult);

        // 6. Upload to board
        System.out.println("Uploading...");
        String uploadResult = arduino.upload("MyRobot", "arduino:avr:uno", "/dev/ttyACM0");
        System.out.println(uploadResult);

        System.out.println("Done!");
    }
}
```

## Troubleshooting

### Java Native Access Warning

If you see warnings about restricted methods:

```bash
java --enable-native-access=ALL-UNNAMED -cp target/classes com.anode.arduino.Example
```

### Cannot Find Board

Make sure your Arduino is connected:

```bash
# Linux: Check /dev
ls /dev/tty*

# macOS: Check /dev
ls /dev/cu.*

# Windows: Check Device Manager
# Look for COM ports
```

### Core Not Found

Always run `coreUpdateIndex()` first:

```java
arduino.coreUpdateIndex();
arduino.coreInstall("arduino:avr");
```

### Permission Denied (Linux)

Add your user to the dialout group:

```bash
sudo usermod -a -G dialout $USER
# Log out and back in
```

## Next Steps

- Read [README.md](README.md) for full API documentation
- Check [ARCHITECTURE.md](ARCHITECTURE.md) to understand how it works
- Browse [Example.java](src/main/java/com/anode/arduino/Example.java) for more examples

## Need Help?

- Check the [Arduino CLI docs](https://arduino.github.io/arduino-cli/)
- View FQBNs: `arduino.boardListAll()`
- Debug: Add print statements to see command output

## Tips & Tricks

### Finding Board FQBNs

```java
// Search for your board
System.out.println(arduino.boardSearch("esp32"));

// Get details about a board
System.out.println(arduino.boardDetails("esp32:esp32:esp32"));
```

### Custom Commands

For anything not in the API:

```java
// Execute any arduino-cli command
String output = arduino.exec("config dump");
String boards = arduino.exec("board listall esp");
```

### Verify Installation

```bash
# Quick test that everything works
java -cp target/classes com.anode.arduino.Example
```

You should see arduino-cli version and board search results!

---

**Happy Making! 🚀**
