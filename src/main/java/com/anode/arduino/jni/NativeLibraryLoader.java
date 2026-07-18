package com.anode.arduino.jni;

import java.io.*;
import java.nio.file.*;

public class NativeLibraryLoader {

    private static final String TEMP_DIR_PREFIX = "j4ino_";
    private static Path extractedArduinoCLI = null;
    private static Path extractedJNILib = null;

    /**
     * Load the JNI wrapper library from embedded resources
     */
    public static void loadJNILibrary() {
        if (extractedJNILib != null) {
            return; // Already loaded
        }

        String platform = detectPlatform();
        String arch = detectArchitecture();
        String libraryName = getLibraryName(platform);
        String resourcePath = "/native/" + platform + "-" + arch + "/" + libraryName;

        try {
            extractedJNILib = extractResource(resourcePath, libraryName);
            System.load(extractedJNILib.toAbsolutePath().toString());
        } catch (Exception e) {
            throw new RuntimeException("Failed to load JNI library: " + e.getMessage(), e);
        }
    }

    /**
     * Extract arduino-cli binary from embedded resources, or fall back to system PATH.
     * Light JARs (without bundled arduino-cli) rely on the system PATH fallback.
     *
     * @return Path to the arduino-cli binary
     */
    public static Path getArduinoCLI() {
        if (extractedArduinoCLI != null && Files.exists(extractedArduinoCLI)) {
            return extractedArduinoCLI;
        }

        String platform = detectPlatform();
        String arch = detectArchitecture();
        String binaryName = platform.equals("windows") ? "arduino-cli.exe" : "arduino-cli";
        String resourcePath = "/arduino-cli/" + platform + "-" + arch + "/" + binaryName;

        // Try bundled binary first (fat JAR)
        if (NativeLibraryLoader.class.getResourceAsStream(resourcePath) != null) {
            try {
                extractedArduinoCLI = extractResource(resourcePath, binaryName);
                if (!platform.equals("windows")) {
                    extractedArduinoCLI.toFile().setExecutable(true, false);
                }
                return extractedArduinoCLI;
            } catch (Exception e) {
                throw new RuntimeException("Failed to extract bundled arduino-cli: " + e.getMessage(), e);
            }
        }

        // Light JAR: resolve from system PATH
        extractedArduinoCLI = resolveFromPath(binaryName);
        if (extractedArduinoCLI == null) {
            throw new RuntimeException(
                "arduino-cli not bundled in this JAR and not found on system PATH. " +
                "Install arduino-cli or use the fat JAR.");
        }
        return extractedArduinoCLI;
    }

    private static Path resolveFromPath(String binaryName) {
        String pathEnv = System.getenv("PATH");
        if (pathEnv == null) return null;
        for (String dir : pathEnv.split(File.pathSeparator)) {
            Path candidate = Paths.get(dir, binaryName);
            if (Files.isExecutable(candidate)) {
                return candidate;
            }
        }
        return null;
    }

    /**
     * Extract a resource to a temporary directory
     */
    private static Path extractResource(String resourcePath, String fileName) throws IOException {
        // Create temp directory
        Path tempDir = Files.createTempDirectory(TEMP_DIR_PREFIX);
        tempDir.toFile().deleteOnExit();

        Path targetFile = tempDir.resolve(fileName);
        targetFile.toFile().deleteOnExit();

        // Extract resource
        try (InputStream in = NativeLibraryLoader.class.getResourceAsStream(resourcePath)) {
            if (in == null) {
                throw new IOException("Resource not found: " + resourcePath);
            }
            Files.copy(in, targetFile, StandardCopyOption.REPLACE_EXISTING);
        }

        return targetFile;
    }

    /**
     * Detect operating system
     */
    private static String detectPlatform() {
        String os = System.getProperty("os.name").toLowerCase();
        if (os.contains("win")) {
            return "windows";
        } else if (os.contains("mac") || os.contains("darwin")) {
            return "macos";
        } else if (os.contains("nix") || os.contains("nux") || os.contains("aix")) {
            return "linux";
        }
        throw new UnsupportedOperationException("Unsupported platform: " + os);
    }

    /**
     * Detect system architecture
     */
    private static String detectArchitecture() {
        String arch = System.getProperty("os.arch").toLowerCase();
        if (arch.contains("amd64") || arch.contains("x86_64")) {
            return "x86_64";
        } else if (arch.contains("aarch64") || arch.contains("arm64")) {
            return "aarch64";
        } else if (arch.contains("arm")) {
            return "arm";
        }
        throw new UnsupportedOperationException("Unsupported architecture: " + arch);
    }

    /**
     * Get the library file name for the platform
     */
    private static String getLibraryName(String platform) {
        switch (platform) {
            case "windows":
                return "arduino_cli_wrapper.dll";
            case "macos":
                return "libarduino_cli_wrapper.dylib";
            case "linux":
                return "libarduino_cli_wrapper.so";
            default:
                throw new UnsupportedOperationException("Unsupported platform: " + platform);
        }
    }
}
