# J4ino Architecture

## Overview

J4ino is a fully embedded Arduino CLI library for Java that requires zero external dependencies. It bundles arduino-cli binaries for all major platforms and automatically extracts them at runtime.

## Architecture Layers

```
┌─────────────────────────────────────────────────┐
│           User Application Layer                │
│  (Uses ArduinoCLI or ArduinoCLINative APIs)    │
└─────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────┐
│         High-Level API (ArduinoCLI)            │
│  • boardList(), compile(), upload(), etc.       │
│  • Convenient wrapper methods                   │
└─────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────┐
│      JNI Interface (ArduinoCLINative)          │
│  • Native method declarations                   │
│  • compile(), upload(), exec()                  │
└─────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────┐
│      Resource Loader (NativeLibraryLoader)     │
│  • Platform detection                           │
│  • Binary extraction to temp directory          │
│  • JNI library loading                          │
└─────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────┐
│    Native C Layer (arduino_cli_wrapper.c)      │
│  • popen() for process execution                │
│  • Output capture and buffering                 │
│  • JNI glue code                                │
└─────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────┐
│       Embedded arduino-cli Binary              │
│  • Extracted from resources at runtime          │
│  • Platform-specific binaries                   │
└─────────────────────────────────────────────────┘
```

## Component Details

### 1. High-Level API (`ArduinoCLI.java`)

**Purpose**: Provides a clean, easy-to-use Java API for common Arduino CLI operations.

**Key Features**:
- Board management (list, search, details)
- Core management (install, list, update)
- Library management (search, install, list)
- Sketch operations (compile, upload, create)
- Configuration access

**Example**:
```java
ArduinoCLI arduino = new ArduinoCLI();
arduino.coreInstall("arduino:avr");
arduino.compile("/path/to/sketch", "arduino:avr:uno");
```

### 2. JNI Interface (`ArduinoCLINative.java`)

**Purpose**: Defines the native methods that bridge Java and C code.

**Native Methods**:
- `native String compile(String sketchPath, String fqbn)`
- `native String upload(String sketchPath, String fqbn, String port)`
- `native String exec(String command)`

**Initialization**:
- Static block loads the native library via `NativeLibraryLoader`
- Thread-safe singleton pattern ensures single load

### 3. Resource Loader (`NativeLibraryLoader.java`)

**Purpose**: Handles platform detection and resource extraction.

**Responsibilities**:
1. **Platform Detection**:
   - OS: Windows, macOS, Linux
   - Architecture: x86_64, aarch64, arm

2. **Resource Extraction**:
   - Extracts arduino-cli binary from JAR resources
   - Extracts JNI wrapper library
   - Places in temporary directory with cleanup

3. **Permission Management**:
   - Sets executable permissions on Unix systems
   - Handles platform-specific file paths

**Extraction Flow**:
```
┌─────────────────────┐
│  JAR Resources      │
│  /arduino-cli/      │
│  /native/           │
└──────────┬──────────┘
           ↓
    detectPlatform()
    detectArchitecture()
           ↓
    extractResource()
           ↓
┌─────────────────────┐
│  /tmp/j4ino_*/      │
│  ├── arduino-cli    │
│  └── libarduino_*.so│
└─────────────────────┘
```

### 4. Native C Layer (`arduino_cli_wrapper.c`)

**Purpose**: Implements the actual command execution using system calls.

**Key Function**: `run_process(const char* cmd)`
- Uses `popen()` to execute shell commands
- Captures stdout in a dynamically allocated buffer
- Returns output as C string for JNI conversion

**JNI Methods**:
Each method follows this pattern:
1. Extract Java strings to C strings
2. Build command string
3. Execute via `run_process()`
4. Convert output to Java string
5. Clean up resources

**Memory Management**:
- Dynamic allocation for output buffer
- Proper cleanup with `free()`
- JNI string release after use

### 5. Embedded Binaries

**arduino-cli Binaries**:
- Linux x86_64: 17 MB
- Linux ARM64: 16 MB
- macOS x86_64: 18 MB
- macOS ARM64: 16 MB
- Windows x86_64: 17 MB

**Total Size**: ~172 MB (all platforms)

**Location in JAR**:
```
/arduino-cli/
  ├── linux-x86_64/arduino-cli
  ├── linux-aarch64/arduino-cli
  ├── macos-x86_64/arduino-cli
  ├── macos-aarch64/arduino-cli
  └── windows-x86_64/arduino-cli.exe
```

**JNI Libraries**:
```
/native/
  ├── linux-x86_64/libarduino_cli_wrapper.so
  ├── linux-aarch64/libarduino_cli_wrapper.so
  ├── macos-x86_64/libarduino_cli_wrapper.dylib
  ├── macos-aarch64/libarduino_cli_wrapper.dylib
  └── windows-x86_64/arduino_cli_wrapper.dll
```

## Build Process

### Build Pipeline

```
┌──────────────────────┐
│ download-arduino-    │
│ cli.sh               │
│ Downloads binaries   │
└──────────┬───────────┘
           ↓
┌──────────────────────┐
│ build-native.sh      │
│ Compiles C code      │
│ Creates .so/.dylib   │
└──────────┬───────────┘
           ↓
┌──────────────────────┐
│ javac                │
│ Compiles Java        │
└──────────┬───────────┘
           ↓
┌──────────────────────┐
│ Copy resources       │
│ to target/classes    │
└──────────┬───────────┘
           ↓
┌──────────────────────┐
│ jar cvf              │
│ Create JAR           │
└──────────────────────┘
```

### Compile-Time Dependencies

- Java 11+ (for javac)
- GCC/Clang (for C compilation)
- JNI headers (from JDK)
- curl (for downloading binaries)
- tar/unzip (for extracting archives)

### Runtime Dependencies

**Zero!** Everything is embedded in the JAR.

## Execution Flow

### First Use
```
1. User creates ArduinoCLI instance
   ↓
2. Static initializer in ArduinoCLINative runs
   ↓
3. NativeLibraryLoader.loadJNILibrary() called
   ↓
4. Platform and architecture detected
   ↓
5. JNI library extracted to /tmp
   ↓
6. System.load() loads the native library
   ↓
7. NativeLibraryLoader.getArduinoCLI() called
   ↓
8. arduino-cli binary extracted to /tmp
   ↓
9. Execute permissions set (Unix)
   ↓
10. Ready for use!
```

### Subsequent Calls
```
User calls arduino.compile()
   ↓
ArduinoCLI.compile() formats command
   ↓
ArduinoCLINative.exec() (native method)
   ↓
JNI wrapper in C
   ↓
popen("/tmp/j4ino_*/arduino-cli compile ...")
   ↓
Capture output
   ↓
Return to Java as String
```

## Platform Support Matrix

| Platform       | x86_64 | ARM64 | ARM32 |
|----------------|--------|-------|-------|
| Linux          | ✅     | ✅    | ❌    |
| macOS          | ✅     | ✅    | N/A   |
| Windows        | ✅     | ❌    | ❌    |

## Security Considerations

### Temporary File Handling
- Files extracted to OS temp directory
- `deleteOnExit()` ensures cleanup
- Random directory names prevent conflicts

### Command Injection
- Currently vulnerable to shell injection
- Future: Use ProcessBuilder instead of popen
- Or: Sanitize inputs before execution

### Permissions
- Extracted binaries executable by all users
- No privilege escalation
- Uses user's temp directory

## Performance Characteristics

### Startup Overhead
- First call: ~50-100ms (extraction + loading)
- Subsequent calls: <1ms overhead
- Binary extraction is one-time per JVM

### Memory Usage
- Native binary: 15-18 MB on disk (in temp)
- JNI library: <100 KB
- Heap: Minimal (only output strings)

### I/O Considerations
- Each command spawns a new process
- Output buffered in memory
- Large outputs may cause memory pressure

## Future Enhancements

### Planned Improvements
1. **ProcessBuilder Migration**: Replace popen with ProcessBuilder for better security
2. **JSON Parsing**: Parse arduino-cli JSON output into Java objects
3. **Async Operations**: Support for long-running operations with callbacks
4. **Streaming Output**: Real-time output for compile/upload progress
5. **Resource Cleanup**: Better temp file management
6. **Error Handling**: Structured exception types

### Possible Optimizations
- Compress binaries (gzip)
- Lazy extraction (only when first used)
- Persistent cache (avoid re-extraction)
- Platform-specific JARs (reduce size)

## Development Guide

### Adding New API Methods

1. Add method to `ArduinoCLI.java`:
```java
public String myNewCommand(String arg) {
    return exec("my-command " + arg);
}
```

2. No C changes needed if using `exec()`!

### Supporting New Platforms

1. Download binary for new platform
2. Add to `src/main/resources/arduino-cli/{platform}-{arch}/`
3. Update `NativeLibraryLoader.detectPlatform()` or `detectArchitecture()`
4. Build native library for that platform
5. Add to resources

### Debugging

**Enable JNI logging**:
```bash
java -Xcheck:jni -verbose:jni -cp target/classes com.anode.arduino.Example
```

**Check extracted files**:
```bash
ls -la /tmp/j4ino_*
```

**Trace command execution**:
Modify `arduino_cli_wrapper.c` to print commands before execution.

## Licensing

- **J4ino Code**: MIT License
- **arduino-cli**: GPL 3.0 (included as embedded binary)
- **Distribution**: Ensure GPL compliance when distributing

## References

- [JNI Specification](https://docs.oracle.com/javase/8/docs/technotes/guides/jni/)
- [Arduino CLI Documentation](https://arduino.github.io/arduino-cli/)
- [popen() Manual](https://man7.org/linux/man-pages/man3/popen.3.html)
