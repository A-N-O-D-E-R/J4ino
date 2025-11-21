# J4ino Makefile - Cross-platform JNI library build system
# Supports native and cross-compilation for all target platforms

.PHONY: all clean help native linux-x86_64 linux-aarch64 macos-x86_64 macos-aarch64 windows-x86_64 \
        java compile-java jar download-arduino test install-cross-tools

# === Configuration ===
VERSION := 1.0
PROJECT_NAME := j4ino
JNI_LIB_NAME := arduino_cli_wrapper

# Directories
SRC_DIR := src/main
C_DIR := $(SRC_DIR)/C
JAVA_DIR := $(SRC_DIR)/java
RESOURCE_DIR := $(SRC_DIR)/resources
BUILD_DIR := build
TARGET_DIR := target/classes
NATIVE_BUILD := $(BUILD_DIR)/native
NATIVE_RESOURCE := $(RESOURCE_DIR)/native

# Java settings
JAVAC := javac
JAVA := java
JAR := jar
JAVA_VERSION := 11
JAVA_HOME ?= $(shell java -XshowSettings:properties -version 2>&1 | grep 'java.home' | sed 's/.*= //')

# Compiler settings
CC := gcc
CFLAGS := -fPIC -O2 -Wall
INCLUDES := -I"$(JAVA_HOME)/include"

# Source files
C_SOURCES := $(C_DIR)/$(JNI_LIB_NAME).c
JNI_HEADER := $(C_DIR)/com_anode_arduino_jni_ArduinoCLINative.h

# === Platform Detection ===
UNAME_S := $(shell uname -s)
UNAME_M := $(shell uname -m)

ifeq ($(UNAME_S),Linux)
    PLATFORM := linux
    INCLUDES += -I"$(JAVA_HOME)/include/linux"
    NATIVE_EXT := .so
    LDFLAGS := -shared
    ifeq ($(UNAME_M),x86_64)
        ARCH := x86_64
    else ifeq ($(UNAME_M),aarch64)
        ARCH := aarch64
    endif
else ifeq ($(UNAME_S),Darwin)
    PLATFORM := macos
    INCLUDES += -I"$(JAVA_HOME)/include/darwin"
    NATIVE_EXT := .dylib
    LDFLAGS := -dynamiclib
    ifeq ($(UNAME_M),x86_64)
        ARCH := x86_64
    else ifeq ($(UNAME_M),arm64)
        ARCH := aarch64
    endif
else ifeq ($(findstring MINGW,$(UNAME_S)),MINGW)
    PLATFORM := windows
    INCLUDES += -I"$(JAVA_HOME)/include/win32"
    NATIVE_EXT := .dll
    LDFLAGS := -shared
    ARCH := x86_64
else ifeq ($(findstring MSYS,$(UNAME_S)),MSYS)
    PLATFORM := windows
    INCLUDES += -I"$(JAVA_HOME)/include/win32"
    NATIVE_EXT := .dll
    LDFLAGS := -shared
    ARCH := x86_64
endif

NATIVE_LIB := lib$(JNI_LIB_NAME)$(NATIVE_EXT)
ifeq ($(PLATFORM),windows)
    NATIVE_LIB := $(JNI_LIB_NAME).dll
endif

# === Cross-compilation toolchains ===
# Linux ARM64
CC_LINUX_AARCH64 := aarch64-linux-gnu-gcc
CFLAGS_LINUX_AARCH64 := $(CFLAGS)
LDFLAGS_LINUX_AARCH64 := -shared

# macOS (requires osxcross)
CC_MACOS_X86_64 := x86_64-apple-darwin20-gcc
CC_MACOS_AARCH64 := aarch64-apple-darwin20-gcc
LDFLAGS_MACOS := -dynamiclib

# Windows (MinGW)
CC_WINDOWS_X86_64 := x86_64-w64-mingw32-gcc
CFLAGS_WINDOWS := $(CFLAGS)
LDFLAGS_WINDOWS := -shared

# === Targets ===

all: help

help:
	@echo "J4ino Build System"
	@echo "=================="
	@echo ""
	@echo "Detected platform: $(PLATFORM)-$(ARCH)"
	@echo ""
	@echo "Main targets:"
	@echo "  make native              - Build for current platform"
	@echo "  make all-platforms       - Build for all platforms (requires cross-compilers)"
	@echo "  make java                - Compile Java classes"
	@echo "  make jar                 - Create distributable JAR"
	@echo "  make download-arduino    - Download arduino-cli binaries"
	@echo "  make test                - Run example"
	@echo "  make clean               - Clean build artifacts"
	@echo ""
	@echo "Platform-specific targets:"
	@echo "  make linux-x86_64        - Build Linux x86_64 library"
	@echo "  make linux-aarch64       - Build Linux ARM64 library (cross-compile)"
	@echo "  make macos-x86_64        - Build macOS Intel library (cross-compile)"
	@echo "  make macos-aarch64       - Build macOS ARM64 library (cross-compile)"
	@echo "  make windows-x86_64      - Build Windows x64 library (cross-compile)"
	@echo ""
	@echo "Setup:"
	@echo "  make install-cross-tools - Install cross-compilation tools (Debian/Ubuntu)"
	@echo ""
	@echo "Docker build (recommended for cross-compilation):"
	@echo "  make docker-build        - Build all platforms in Docker"

# === Native Build (Current Platform) ===

native: $(JNI_HEADER) $(NATIVE_RESOURCE)/$(PLATFORM)-$(ARCH)/$(NATIVE_LIB)
	@echo "✓ Built native library for $(PLATFORM)-$(ARCH)"

$(NATIVE_RESOURCE)/$(PLATFORM)-$(ARCH)/$(NATIVE_LIB): $(C_SOURCES)
	@echo "Building native library for $(PLATFORM)-$(ARCH)..."
	@mkdir -p $(NATIVE_RESOURCE)/$(PLATFORM)-$(ARCH)
	@mkdir -p $(NATIVE_BUILD)
	$(CC) $(CFLAGS) $(INCLUDES) $(LDFLAGS) -o $@ $^
	@cp $@ $(NATIVE_BUILD)/
	@echo "✓ Native library built: $@"

# === JNI Header Generation ===

$(JNI_HEADER): $(JAVA_DIR)/com/anode/arduino/jni/ArduinoCLINative.java $(JAVA_DIR)/com/anode/arduino/jni/NativeLibraryLoader.java
	@echo "Generating JNI header..."
	@mkdir -p $(TARGET_DIR)
	@$(JAVAC) -h $(C_DIR) -d $(TARGET_DIR) \
		$(JAVA_DIR)/com/anode/arduino/jni/NativeLibraryLoader.java \
		$(JAVA_DIR)/com/anode/arduino/jni/ArduinoCLINative.java
	@echo "✓ JNI header generated"

# === Cross-compilation Targets ===

linux-x86_64: $(JNI_HEADER)
	@echo "Building for Linux x86_64..."
	@mkdir -p $(NATIVE_RESOURCE)/linux-x86_64
	$(CC) $(CFLAGS) $(INCLUDES) -I"$(JAVA_HOME)/include/linux" -shared \
		-o $(NATIVE_RESOURCE)/linux-x86_64/lib$(JNI_LIB_NAME).so $(C_SOURCES)
	@echo "✓ Linux x86_64 library built"

linux-aarch64: $(JNI_HEADER)
	@echo "Building for Linux ARM64..."
	@mkdir -p $(NATIVE_RESOURCE)/linux-aarch64
	$(CC_LINUX_AARCH64) $(CFLAGS_LINUX_AARCH64) $(INCLUDES) -I"$(JAVA_HOME)/include/linux" \
		$(LDFLAGS_LINUX_AARCH64) -o $(NATIVE_RESOURCE)/linux-aarch64/lib$(JNI_LIB_NAME).so $(C_SOURCES)
	@echo "✓ Linux ARM64 library built"

macos-x86_64: $(JNI_HEADER)
	@echo "Building for macOS x86_64..."
	@mkdir -p $(NATIVE_RESOURCE)/macos-x86_64
	@if command -v $(CC_MACOS_X86_64) >/dev/null 2>&1; then \
		$(CC_MACOS_X86_64) $(CFLAGS) $(INCLUDES) -I"$(JAVA_HOME)/include/darwin" \
			$(LDFLAGS_MACOS) -o $(NATIVE_RESOURCE)/macos-x86_64/lib$(JNI_LIB_NAME).dylib $(C_SOURCES); \
		echo "✓ macOS x86_64 library built"; \
	else \
		echo "⚠ macOS x86_64 cross-compiler not found. Install osxcross or use Docker build."; \
		exit 1; \
	fi

macos-aarch64: $(JNI_HEADER)
	@echo "Building for macOS ARM64..."
	@mkdir -p $(NATIVE_RESOURCE)/macos-aarch64
	@if command -v $(CC_MACOS_AARCH64) >/dev/null 2>&1; then \
		$(CC_MACOS_AARCH64) $(CFLAGS) $(INCLUDES) -I"$(JAVA_HOME)/include/darwin" \
			$(LDFLAGS_MACOS) -o $(NATIVE_RESOURCE)/macos-aarch64/lib$(JNI_LIB_NAME).dylib $(C_SOURCES); \
		echo "✓ macOS ARM64 library built"; \
	else \
		echo "⚠ macOS ARM64 cross-compiler not found. Install osxcross or use Docker build."; \
		exit 1; \
	fi

windows-x86_64: $(JNI_HEADER)
	@echo "Building for Windows x64..."
	@mkdir -p $(NATIVE_RESOURCE)/windows-x86_64
	@if command -v $(CC_WINDOWS_X86_64) >/dev/null 2>&1; then \
		$(CC_WINDOWS_X86_64) $(CFLAGS_WINDOWS) $(INCLUDES) -I"$(JAVA_HOME)/include/win32" \
			$(LDFLAGS_WINDOWS) -o $(NATIVE_RESOURCE)/windows-x86_64/$(JNI_LIB_NAME).dll $(C_SOURCES); \
		echo "✓ Windows x64 library built"; \
	else \
		echo "⚠ Windows x64 cross-compiler not found. Install mingw-w64 or use Docker build."; \
		exit 1; \
	fi

# Build all platforms
all-platforms: linux-x86_64 linux-aarch64 macos-x86_64 macos-aarch64 windows-x86_64
	@echo ""
	@echo "✓ All platform libraries built successfully!"
	@echo ""
	@find $(NATIVE_RESOURCE) -type f -name "*.so" -o -name "*.dylib" -o -name "*.dll"

# === Java Compilation ===

java: compile-java
	@echo "✓ Java classes compiled"

compile-java: $(JNI_HEADER)
	@echo "Compiling Java classes..."
	@mkdir -p $(TARGET_DIR)
	@$(JAVAC) --release $(JAVA_VERSION) -d $(TARGET_DIR) \
		$(JAVA_DIR)/com/anode/arduino/jni/*.java \
		$(JAVA_DIR)/com/anode/arduino/*.java
	@echo "✓ Java compilation complete"

# === JAR Creation ===

jar: compile-java native
	@echo "Creating JAR with embedded resources..."
	@mkdir -p $(TARGET_DIR)
	@cp -r $(RESOURCE_DIR)/* $(TARGET_DIR)/
	@cd $(TARGET_DIR) && $(JAR) cvf ../../$(PROJECT_NAME)-$(VERSION).jar .
	@echo "✓ JAR created: $(PROJECT_NAME)-$(VERSION).jar"

# === Arduino CLI Download ===

download-arduino:
	@echo "Downloading arduino-cli binaries..."
	@./download-arduino-cli.sh
	@echo "✓ Arduino CLI binaries downloaded"

# === Testing ===

test: compile-java
	@echo "Running example..."
	@cp -r $(RESOURCE_DIR)/* $(TARGET_DIR)/ 2>/dev/null || true
	@$(JAVA) --enable-native-access=ALL-UNNAMED -cp $(TARGET_DIR) com.anode.arduino.Example

# === Cross-compilation Tools Installation ===

install-cross-tools:
	@echo "Installing cross-compilation toolchains..."
	@if [ "$$(uname -s)" = "Linux" ]; then \
		echo "Detected Linux - installing cross-compilers..."; \
		sudo apt-get update; \
		sudo apt-get install -y \
			gcc-aarch64-linux-gnu \
			g++-aarch64-linux-gnu \
			gcc-mingw-w64-x86-64 \
			g++-mingw-w64-x86-64; \
		echo "✓ Cross-compilation tools installed"; \
		echo ""; \
		echo "Note: macOS cross-compilation requires osxcross:"; \
		echo "  https://github.com/tpoechtrager/osxcross"; \
	else \
		echo "Automatic installation only supported on Linux"; \
		echo "Please install cross-compilers manually for your platform"; \
		exit 1; \
	fi

# === Docker Build ===

docker-build:
	@echo "Building all platforms in Docker..."
	@if [ ! -f "Dockerfile.build" ]; then \
		echo "Creating Dockerfile.build..."; \
		$(MAKE) create-dockerfile; \
	fi
	@docker build -f Dockerfile.build -t j4ino-builder .
	@docker run --rm -v $$(pwd):/workspace j4ino-builder
	@echo "✓ Docker build complete"

create-dockerfile:
	@echo "FROM ubuntu:22.04" > Dockerfile.build
	@echo "" >> Dockerfile.build
	@echo "RUN apt-get update && apt-get install -y \\" >> Dockerfile.build
	@echo "    gcc g++ make \\" >> Dockerfile.build
	@echo "    gcc-aarch64-linux-gnu g++-aarch64-linux-gnu \\" >> Dockerfile.build
	@echo "    gcc-mingw-w64-x86-64 g++-mingw-w64-x86-64 \\" >> Dockerfile.build
	@echo "    openjdk-11-jdk \\" >> Dockerfile.build
	@echo "    curl unzip tar" >> Dockerfile.build
	@echo "" >> Dockerfile.build
	@echo "WORKDIR /workspace" >> Dockerfile.build
	@echo "" >> Dockerfile.build
	@echo 'CMD ["make", "all-platforms"]' >> Dockerfile.build
	@echo "✓ Dockerfile.build created"

# === Clean ===

clean:
	@echo "Cleaning build artifacts..."
	@rm -rf $(BUILD_DIR)
	@rm -rf $(TARGET_DIR)
	@rm -f $(PROJECT_NAME)-*.jar
	@rm -f $(C_DIR)/*.h.gch
	@rm -f *.so *.dll *.dylib
	@echo "✓ Clean complete"

clean-all: clean
	@echo "Cleaning all generated files including native libraries..."
	@rm -rf $(NATIVE_RESOURCE)/*/lib*.so
	@rm -rf $(NATIVE_RESOURCE)/*/lib*.dylib
	@rm -rf $(NATIVE_RESOURCE)/*/*.dll
	@echo "✓ Deep clean complete"

# === Info ===

info:
	@echo "Build Configuration"
	@echo "==================="
	@echo "Platform:        $(PLATFORM)"
	@echo "Architecture:    $(ARCH)"
	@echo "Java Home:       $(JAVA_HOME)"
	@echo "C Compiler:      $(CC)"
	@echo "Native Lib:      $(NATIVE_LIB)"
	@echo "Native Ext:      $(NATIVE_EXT)"
	@echo ""
	@echo "Cross-compilers:"
	@command -v $(CC_LINUX_AARCH64) >/dev/null 2>&1 && echo "  Linux ARM64:   ✓" || echo "  Linux ARM64:   ✗"
	@command -v $(CC_WINDOWS_X86_64) >/dev/null 2>&1 && echo "  Windows x64:   ✓" || echo "  Windows x64:   ✗"
	@command -v $(CC_MACOS_X86_64) >/dev/null 2>&1 && echo "  macOS x86_64:  ✓" || echo "  macOS x86_64:  ✗"
	@command -v $(CC_MACOS_AARCH64) >/dev/null 2>&1 && echo "  macOS ARM64:   ✓" || echo "  macOS ARM64:   ✗"
