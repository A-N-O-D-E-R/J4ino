package com.anode.arduino;

import com.anode.arduino.jni.ArduinoCLINative;
import com.anode.arduino.jni.NativeLibraryLoader;

import java.nio.file.Path;

/**
 * High-level wrapper for Arduino CLI
 * Uses embedded arduino-cli binary - no external installation required!
 */
public class ArduinoCLI {

    private final String arduinoCliPath;

    /**
     * Create instance using embedded arduino-cli binary
     */
    public ArduinoCLI() {
        Path cli = NativeLibraryLoader.getArduinoCLI();
        this.arduinoCliPath = cli.toAbsolutePath().toString();
    }

    /**
     * Get arduino-cli version
     */
    public String version() {
        return exec("version");
    }

    /**
     * List installed boards
     */
    public String boardList() {
        return exec("board list");
    }

    /**
     * List available boards
     */
    public String boardListAll() {
        return exec("board listall");
    }

    /**
     * Search for boards
     */
    public String boardSearch(String query) {
        return exec("board search " + query);
    }

    /**
     * Install board core
     */
    public String coreInstall(String core) {
        return exec("core install " + core);
    }

    /**
     * List installed cores
     */
    public String coreList() {
        return exec("core list");
    }

    /**
     * Update index
     */
    public String coreUpdateIndex() {
        return exec("core update-index");
    }

    /**
     * Search for libraries
     */
    public String libSearch(String query) {
        return exec("lib search " + query);
    }

    /**
     * Install library
     */
    public String libInstall(String library) {
        return exec("lib install " + library);
    }

    /**
     * List installed libraries
     */
    public String libList() {
        return exec("lib list");
    }

    /**
     * Compile Arduino sketch
     * @param sketchPath Path to sketch directory
     * @param fqbn Fully Qualified Board Name (e.g., "arduino:avr:uno")
     */
    public String compile(String sketchPath, String fqbn) {
        return ArduinoCLINative.compile(sketchPath, fqbn);
    }

    /**
     * Upload sketch to board
     * @param sketchPath Path to sketch directory
     * @param fqbn Fully Qualified Board Name
     * @param port Serial port (e.g., "/dev/ttyACM0", "COM3")
     */
    public String upload(String sketchPath, String fqbn, String port) {
        return ArduinoCLINative.upload(sketchPath, fqbn, port);
    }

    /**
     * Upload pre-compiled hex file to board
     * @param hexFilePath Path to the .hex file
     * @param fqbn Fully Qualified Board Name
     * @param port Serial port (e.g., "/dev/ttyACM0", "COM3")
     */
    public String uploadHex(String hexFilePath, String fqbn, String port) {
        return exec("upload -p " + port + " --fqbn " + fqbn + " --input-file " + hexFilePath);
    }

    /**
     * Compile and upload in one step
     */
    public String compileAndUpload(String sketchPath, String fqbn, String port) {
        return exec("compile --upload -p " + port + " --fqbn " + fqbn + " " + sketchPath);
    }

    /**
     * Create new sketch
     */
    public String sketchNew(String sketchName) {
        return exec("sketch new " + sketchName);
    }

    /**
     * Get board details by FQBN
     */
    public String boardDetails(String fqbn) {
        return exec("board details --fqbn " + fqbn);
    }

    /**
     * Get configuration
     */
    public String config() {
        return exec("config dump");
    }

    /**
     * Execute custom arduino-cli command
     * @param command Command to execute (without "arduino-cli" prefix)
     */
    public String exec(String command) {
        return ArduinoCLINative.exec(arduinoCliPath + " " + command);
    }

    /**
     * Get path to embedded arduino-cli binary
     */
    public String getArduinoCliPath() {
        return arduinoCliPath;
    }
}
