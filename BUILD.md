# J4ino Build Guide

Complete guide for building J4ino with Makefile and cross-compilation support.

## Quick Start

```bash
# Build for your current platform
make native

# Compile Java classes
make java

# Run example
make test

# Create distributable JAR
make jar
```

## Prerequisites

### Required
- **Java JDK 11+** with JAVA_HOME set
- **GCC** or compatible C compiler
- **Make** (GNU Make)

### Optional (for cross-compilation)
- **aarch64-linux-gnu-gcc** (Linux ARM64)
- **x86_64-w64-mingw32-gcc** (Windows)
- **osxcross** (macOS - see below)
- **Docker** (easiest for cross-compilation)

## Build Targets

### Main Targets

| Target | Description |
|--------|-------------|
| `make native` | Build JNI library for current platform |
| `make java` | Compile Java classes |
| `make jar` | Create distributable JAR with embedded resources |
| `make test` | Run the example application |
| `make clean` | Remove build artifacts |
| `make help` | Show all available targets |

### Platform-Specific Targets

| Target | Cross-Compiler Required | Output |
|--------|------------------------|---------|
| `make linux-x86_64` | gcc (native on Linux x64) | libarduino_cli_wrapper.so |
| `make linux-aarch64` | aarch64-linux-gnu-gcc | libarduino_cli_wrapper.so |
| `make macos-x86_64` | osxcross | libarduino_cli_wrapper.dylib |
| `make macos-aarch64` | osxcross | libarduino_cli_wrapper.dylib |
| `make windows-x86_64` | x86_64-w64-mingw32-gcc | arduino_cli_wrapper.dll |

### All Platforms

```bash
# Build for all platforms (requires all cross-compilers)
make all-platforms
```

## Native Build (Current Platform)

Build only for your current operating system and architecture:

```bash
# Clean previous builds
make clean

# Build native library
make native

# Compile Java
make java

# Test
make test
```

The native library will be placed in:
- `src/main/resources/native/<platform>-<arch>/`

## Cross-Compilation Setup

### Option 1: Docker (Recommended)

Use Docker for easy cross-compilation without installing toolchains:

```bash
# Build all platforms in Docker
make docker-build
```

This will:
1. Create a Dockerfile with all cross-compilers
2. Build a Docker image
3. Compile all platform libraries
4. Output to `src/main/resources/native/`

### Option 2: Install Cross-Compilers Locally

#### On Ubuntu/Debian

```bash
# Install cross-compilers
make install-cross-tools

# Or manually:
sudo apt-get update
sudo apt-get install -y \
    gcc-aarch64-linux-gnu \
    g++-aarch64-linux-gnu \
    gcc-mingw-w64-x86-64 \
    g++-mingw-w64-x86-64
```

#### On macOS

```bash
# Install Homebrew if needed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install cross-compilers
brew install mingw-w64

# For Linux ARM64 cross-compilation
brew tap messense/macos-cross-toolchains
brew install aarch64-unknown-linux-gnu
```

#### macOS Cross-Compilation (osxcross)

To build macOS binaries from Linux:

```bash
# Clone osxcross
git clone https://github.com/tpoechtrager/osxcross
cd osxcross

# Download macOS SDK (requires macOS or legal download)
# Place MacOSX SDK tar in tarballs/

# Build osxcross
./build.sh

# Add to PATH
export PATH="$PWD/target/bin:$PATH"
```

### Option 3: GitHub Actions / CI

See `.github/workflows/build.yml` (create this for automated builds).

## Building All Platforms

Once cross-compilers are installed:

```bash
# Build all platform libraries
make all-platforms

# Verify
find src/main/resources/native -type f

# Should show:
# src/main/resources/native/linux-x86_64/libarduino_cli_wrapper.so
# src/main/resources/native/linux-aarch64/libarduino_cli_wrapper.so
# src/main/resources/native/macos-x86_64/libarduino_cli_wrapper.dylib
# src/main/resources/native/macos-aarch64/libarduino_cli_wrapper.dylib
# src/main/resources/native/windows-x86_64/arduino_cli_wrapper.dll
```

## Complete Build Process

### Full Release Build

```bash
# 1. Download arduino-cli binaries (one time)
make download-arduino

# 2. Build all platform libraries
make all-platforms

# 3. Compile Java
make java

# 4. Create JAR
make jar

# Result: j4ino-1.0.jar
```

### Testing the JAR

```bash
# Run example
java -cp j4ino-1.0.jar com.anode.arduino.Example

# Use in your project
java -cp j4ino-1.0.jar:myapp.jar com.myapp.Main
```

## Makefile Variables

Override these on the command line:

```bash
# Use different Java version
make java JAVA_VERSION=17

# Use specific compiler
make native CC=clang

# Change build directory
make native BUILD_DIR=mybuild

# Custom Java home
make java JAVA_HOME=/path/to/jdk
```

## Build Configuration

Check your build configuration:

```bash
make info
```

Output example:
```
Build Configuration
===================
Platform:        linux
Architecture:    x86_64
Java Home:       /usr/lib/jvm/java-11-openjdk
C Compiler:      gcc
Native Lib:      libarduino_cli_wrapper.so
Native Ext:      .so

Cross-compilers:
  Linux ARM64:   ✓
  Windows x64:   ✓
  macOS x86_64:  ✗
  macOS ARM64:   ✗
```

## Docker Build Details

### Using the Docker Builder

```bash
# First time: Creates Dockerfile.build
make docker-build

# Subsequent builds: Reuses image
docker run --rm -v $(pwd):/workspace j4ino-builder make all-platforms
```

### Custom Docker Build

```bash
# Create Dockerfile
make create-dockerfile

# Build image
docker build -f Dockerfile.build -t j4ino-builder .

# Run specific target
docker run --rm -v $(pwd):/workspace j4ino-builder make linux-aarch64

# Interactive shell
docker run --rm -it -v $(pwd):/workspace j4ino-builder bash
```

## Troubleshooting

### "Cannot find jni.h"

**Problem**: JNI headers not found

**Solution**:
```bash
# Set JAVA_HOME
export JAVA_HOME=/path/to/jdk

# Or install JDK
sudo apt-get install openjdk-11-jdk  # Debian/Ubuntu
brew install openjdk@11              # macOS
```

### "command not found: aarch64-linux-gnu-gcc"

**Problem**: Cross-compiler not installed

**Solution**:
```bash
# On Linux
make install-cross-tools

# Or use Docker
make docker-build
```

### "Permission denied" when running library

**Problem**: Library not executable

**Solution**:
The Makefile should handle this, but manually:
```bash
chmod +x src/main/resources/native/*/arduino-cli
```

### Cross-compilation fails for macOS

**Problem**: osxcross not set up

**Solution**:
- Use Docker build (easiest)
- Or set up osxcross following official docs
- Or build natively on macOS

### Make version issues

**Problem**: GNU Make features not available

**Solution**:
```bash
# Install GNU Make
sudo apt-get install make     # Linux
brew install make             # macOS

# Check version (need 3.81+)
make --version
```

## Advanced Usage

### Parallel Builds

```bash
# Build with 4 parallel jobs
make -j4 all-platforms
```

### Verbose Output

```bash
# See all commands
make native V=1

# Or remove @ from Makefile commands
```

### Custom Output Directory

```bash
# Build to custom location
make native NATIVE_RESOURCE=/path/to/output
```

### Cleaning

```bash
# Clean build artifacts
make clean

# Clean everything including native libraries
make clean-all

# Clean and rebuild
make clean all
```

## Integration with IDEs

### IntelliJ IDEA

1. Import as Maven/Gradle project
2. Or configure external tools:
   - Program: `make`
   - Arguments: `native java`
   - Working directory: `$ProjectFileDir$`

### VS Code

Create `.vscode/tasks.json`:

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Build Native",
      "type": "shell",
      "command": "make native",
      "group": {
        "kind": "build",
        "isDefault": true
      }
    },
    {
      "label": "Build All",
      "type": "shell",
      "command": "make all-platforms"
    },
    {
      "label": "Test",
      "type": "shell",
      "command": "make test"
    }
  ]
}
```

### Eclipse

1. Right-click project → Build Targets
2. Add targets: native, java, test
3. Double-click to run

## CI/CD Integration

### GitHub Actions Example

Create `.github/workflows/build.yml`:

```yaml
name: Build All Platforms

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v3

    - name: Set up JDK 11
      uses: actions/setup-java@v3
      with:
        java-version: '11'
        distribution: 'temurin'

    - name: Install cross-compilers
      run: make install-cross-tools

    - name: Build all platforms
      run: make all-platforms

    - name: Build JAR
      run: make jar

    - name: Upload artifacts
      uses: actions/upload-artifact@v3
      with:
        name: j4ino-jar
        path: j4ino-*.jar
```

## Build Performance

Typical build times (on i7 laptop):

- Native library (single platform): ~2 seconds
- All platforms: ~10 seconds
- Java compilation: ~3 seconds
- JAR creation: ~5 seconds
- Full clean build: ~20 seconds

## Further Reading

- [Makefile Manual](https://www.gnu.org/software/make/manual/)
- [JNI Specification](https://docs.oracle.com/javase/8/docs/technotes/guides/jni/)
- [Cross-compilation Guide](https://wiki.osdev.org/Cross-Compiler)
- [Docker Multi-platform Builds](https://docs.docker.com/build/building/multi-platform/)
