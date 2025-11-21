package com.anode.arduino;

/**
 * Example usage of J4ino - Fully embedded Arduino CLI for Java
 * No external arduino-cli installation required!
 */
public class Example {

    public static void main(String[] args) {
        System.out.println("=== J4ino - Embedded Arduino CLI for Java ===\n");

        try {
            // Create Arduino CLI instance (automatically extracts embedded binary)
            ArduinoCLI arduino = new ArduinoCLI();

            System.out.println("Arduino CLI extracted to: " + arduino.getArduinoCliPath());
            System.out.println();

            // Test 1: Check version
            System.out.println("1. Arduino CLI Version:");
            System.out.println(arduino.version());
            System.out.println();

            // Test 2: Update core index (required before installing cores)
            System.out.println("2. Updating core index...");
            System.out.println(arduino.coreUpdateIndex());
            System.out.println();

            // Test 3: List connected boards
            System.out.println("3. Connected Boards:");
            String boards = arduino.boardList();
            System.out.println(boards.isEmpty() ? "No boards detected" : boards);
            System.out.println();

            // Test 4: Search for Arduino boards
            System.out.println("4. Searching for Arduino Uno...");
            String search = arduino.boardSearch("uno");
            System.out.println(search);
            System.out.println();

            // Test 5: List installed cores
            System.out.println("5. Installed Cores:");
            String cores = arduino.coreList();
            System.out.println(cores.isEmpty() ? "No cores installed yet" : cores);
            System.out.println();

            // Example: Install Arduino AVR core (uncomment to run)
            /*
            System.out.println("6. Installing Arduino AVR core...");
            System.out.println(arduino.coreInstall("arduino:avr"));
            System.out.println();
            */

            // Example: Compile a sketch (uncomment and modify path)
            /*
            System.out.println("7. Compiling sketch...");
            String compileResult = arduino.compile(
                "/path/to/your/sketch",
                "arduino:avr:uno"
            );
            System.out.println(compileResult);
            System.out.println();
            */

            // Example: Upload to board (uncomment and modify)
            /*
            System.out.println("8. Uploading to board...");
            String uploadResult = arduino.upload(
                "/path/to/your/sketch",
                "arduino:avr:uno",
                "/dev/ttyACM0"  // or "COM3" on Windows
            );
            System.out.println(uploadResult);
            */

            // Example: Execute custom command
            System.out.println("6. Getting configuration...");
            System.out.println(arduino.config());

        } catch (Exception e) {
            System.err.println("Error: " + e.getMessage());
            e.printStackTrace();
        }
    }
}
