# Maven Build Guide for J4ino

Complete guide for building J4ino using Maven with integrated Makefile execution.

## Quick Start

```bash
# Build everything with one command
mvn clean install

# Run the JAR
java -jar target/j4ino-1.0-SNAPSHOT.jar
```

That's it! Maven will automatically:
1. Check for arduino-cli binaries (download if needed)
2. Build the native JNI library for your platform
3. Compile Java classes
4. Package everything into a JAR

## Prerequisites

- **Java JDK 11+**
- **Apache Maven 3.6+**
- **Make** (GNU Make)
- **GCC** (or compatible C compiler)

## Maven Commands

### Standard Build

```bash
# Clean and build
mvn clean install

# Just compile (no tests, no package)
mvn compile

# Package without running tests
mvn package -DskipTests

# Run tests only
mvn test
```

### Build Profiles

J4ino includes several Maven profiles for different build scenarios:

#### 1. Default Profile (Native Build)

Builds for your current platform:

```bash
mvn clean install
```

This runs:
- `make native` - Build native library for current platform
- Java compilation
- Resource bundling
- JAR packaging

#### 2. All Platforms Profile

Build native libraries for all 5 platforms (requires cross-compilers):

```bash
mvn clean install -P all-platforms
```

This runs:
- `make all-platforms` - Cross-compile for Linux, macOS, Windows (x64 & ARM64)
- Java compilation
- Package all libraries in JAR

**Requirements:**
- Cross-compilation toolchains (aarch64-linux-gnu-gcc, mingw-w64, osxcross)
- See [BUILD.md](BUILD.md) for setup instructions

#### 3. Docker Build Profile

Build all platforms using Docker (easiest for cross-compilation):

```bash
mvn clean install -P docker-build
```

This runs:
- `make docker-build` - Build all platforms in Docker container
- Outputs to `src/main/resources/native/`
- Packages everything

**Requirements:**
- Docker installed and running

#### 4. Skip Native Build Profile

Skip native compilation (use pre-built libraries):

```bash
mvn clean install -P skip-native
```

Useful when:
- Libraries are already built
- Building in CI with pre-compiled binaries
- You only want to modify Java code

## Maven Properties

Override these on the command line:

```bash
# Use different make executable
mvn install -Dmake.executable=gmake

# Skip native build
mvn install -DskipNativeBuild=true

# Change Java version
mvn install -Dmaven.compiler.release=17
```

## Build Lifecycle

Maven executes these phases in order:

```
mvn clean install
    │
    ├── clean
    │   └── Deletes target/, build/, *.so, *.dll, *.dylib, *.jar
    │
    ├── initialize
    │   └── Check for arduino-cli binaries
    │       └── Download if missing (make download-arduino)
    │
    ├── generate-resources
    │   └── Build native library (make native)
    │
    ├── process-resources
    │   └── Copy resources to target/classes/
    │
    ├── compile
    │   └── Compile Java sources
    │
    ├── test
    │   └── Run JUnit tests (if any)
    │
    ├── package
    │   └── Create JAR with manifest
    │
    └── install
        └── Install JAR to local Maven repository
```

## Project Structure

```
J4ino/
├── pom.xml                    # Maven configuration
├── Makefile                   # Build system for native code
├── src/
│   └── main/
│       ├── java/              # Java sources
│       ├── C/                 # Native C sources
│       └── resources/         # Embedded binaries
└── target/
    ├── classes/               # Compiled Java + resources
    └── j4ino-1.0-SNAPSHOT.jar # Final JAR
```

## IDE Integration

### IntelliJ IDEA

1. **Import Project:**
   - File → Open → Select `pom.xml`
   - IntelliJ will auto-configure

2. **Run Configurations:**
   - Create Run Configuration → Application
   - Main class: `com.anode.arduino.Example`
   - VM options: `--enable-native-access=ALL-UNNAMED`

3. **Build with Maven:**
   - View → Tool Windows → Maven
   - Execute `clean install`

### Eclipse

1. **Import Project:**
   - File → Import → Maven → Existing Maven Project
   - Select J4ino directory

2. **Build:**
   - Right-click project → Run As → Maven install

### VS Code

1. **Install Extension:**
   - Maven for Java (vscjava.vscode-maven)

2. **Build:**
   - Open Command Palette (Ctrl+Shift+P)
   - "Maven: Execute commands"
   - Select "install"

## Troubleshooting

### "make: command not found"

**Problem:** Make is not installed

**Solution:**
```bash
# Ubuntu/Debian
sudo apt-get install make

# macOS
xcode-select --install
# or
brew install make

# Windows (WSL)
sudo apt-get install make
```

### "Cannot find jni.h"

**Problem:** JAVA_HOME not set or JDK not installed

**Solution:**
```bash
# Check JAVA_HOME
echo $JAVA_HOME

# Set it if needed
export JAVA_HOME=/path/to/jdk

# Or install JDK
sudo apt-get install openjdk-11-jdk  # Linux
brew install openjdk@11              # macOS
```

### Native build fails

**Problem:** GCC or compiler not available

**Solution:**
```bash
# Install GCC
sudo apt-get install build-essential  # Linux
xcode-select --install                # macOS
```

### "Arduino CLI binaries not found"

**Problem:** Binaries haven't been downloaded yet

**Solution:**
```bash
# Download manually
make download-arduino

# Or let Maven download automatically (default behavior)
mvn clean install
```

### Cross-compilation fails

**Problem:** Cross-compilers not installed

**Solutions:**

**Option 1 - Use Docker (easiest):**
```bash
mvn clean install -P docker-build
```

**Option 2 - Install cross-compilers:**
```bash
# On Linux
make install-cross-tools

# Then build
mvn clean install -P all-platforms
```

**Option 3 - Skip cross-compilation:**
```bash
# Build only for current platform
mvn clean install
```

### Tests fail with native library error

**Problem:** Native library not found or permissions issue

**Solution:**
```bash
# Rebuild native library
make clean && make native

# Then run Maven
mvn install
```

### JAR is missing resources

**Problem:** Resources not copied correctly

**Solution:**
```bash
# Clean everything
mvn clean
make clean

# Rebuild from scratch
make download-arduino
mvn install
```

## Advanced Usage

### Multi-Module Projects

If using J4ino as a dependency in a multi-module Maven project:

```xml
<dependency>
    <groupId>com.anode.arduino</groupId>
    <artifactId>j4ino</artifactId>
    <version>1.0-SNAPSHOT</version>
</dependency>
```

### Custom Build Steps

Add custom executions to the antrun plugin:

```xml
<execution>
    <id>custom-step</id>
    <phase>verify</phase>
    <goals>
        <goal>run</goal>
    </goals>
    <configuration>
        <target>
            <exec executable="make">
                <arg value="test"/>
            </exec>
        </target>
    </configuration>
</execution>
```

### Parallel Builds

Speed up Maven builds:

```bash
# Use multiple threads
mvn clean install -T 4

# One thread per CPU core
mvn clean install -T 1C
```

### Offline Builds

Build without downloading dependencies:

```bash
mvn clean install -o
```

### Verbose Output

See detailed build information:

```bash
# Maven debug output
mvn clean install -X

# Makefile verbose output
mvn install -Dmake.executable="make V=1"
```

## CI/CD Integration

### GitHub Actions

```yaml
name: Build

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

    - name: Install Make
      run: sudo apt-get install -y make gcc

    - name: Build with Maven
      run: mvn clean install

    - name: Upload JAR
      uses: actions/upload-artifact@v3
      with:
        name: j4ino-jar
        path: target/*.jar
```

### GitLab CI

```yaml
build:
  image: maven:3.9-eclipse-temurin-11
  before_script:
    - apt-get update && apt-get install -y make gcc
  script:
    - mvn clean install
  artifacts:
    paths:
      - target/*.jar
```

### Jenkins

```groovy
pipeline {
    agent any
    tools {
        maven 'Maven 3.9'
        jdk 'JDK 11'
    }
    stages {
        stage('Build') {
            steps {
                sh 'mvn clean install'
            }
        }
        stage('Archive') {
            steps {
                archiveArtifacts artifacts: 'target/*.jar'
            }
        }
    }
}
```

## Maven vs Make

Both build systems work together:

| Task | Maven Command | Make Command |
|------|--------------|--------------|
| Full build | `mvn clean install` | `make clean jar` |
| Native only | (via Maven phases) | `make native` |
| Java only | `mvn compile` | `make java` |
| Test | `mvn test` | `make test` |
| Clean | `mvn clean` | `make clean` |
| All platforms | `mvn install -P all-platforms` | `make all-platforms` |

**When to use Maven:**
- Standard Java development workflow
- IDE integration
- Dependency management
- CI/CD pipelines
- Publishing to Maven repositories

**When to use Make directly:**
- Quick native-only rebuilds
- Cross-compilation without Java changes
- Manual control over build steps
- Debugging native code issues

## Publishing to Maven Repository

### Local Repository

Already done automatically by `mvn install`:

```bash
mvn install
# JAR installed to ~/.m2/repository/com/anode/arduino/j4ino/1.0-SNAPSHOT/
```

### Remote Repository

Configure in `pom.xml`:

```xml
<distributionManagement>
    <repository>
        <id>myrepo</id>
        <url>https://repo.example.com/maven2</url>
    </repository>
</distributionManagement>
```

Deploy:

```bash
mvn deploy
```

### Maven Central

For public release:
1. Sign up for Sonatype OSSRH
2. Add GPG signing
3. Configure `settings.xml`
4. Run `mvn deploy`

See: https://central.sonatype.org/publish/

## Performance Tips

1. **Skip tests during development:**
   ```bash
   mvn install -DskipTests
   ```

2. **Avoid rebuilding native lib:**
   ```bash
   # After first build, use skip-native profile for Java-only changes
   mvn install -P skip-native
   ```

3. **Use Maven Daemon:**
   ```bash
   # Install mvnd (faster Maven)
   brew install mvnd  # or download from https://github.com/apache/maven-mvnd

   # Use instead of mvn
   mvnd clean install
   ```

4. **Parallel compilation:**
   ```bash
   mvn install -T 4
   ```

## Summary

✅ **Simple:** Just run `mvn clean install`
✅ **Integrated:** Makefile automatically invoked
✅ **Flexible:** Profiles for different scenarios
✅ **Standard:** Works with all Java tools and IDEs
✅ **Complete:** Handles native + Java in one command

The Maven build is now the **primary build method** for J4ino!
