package com.anode.arduino.jni;

public class ArduinoCLINative {

    private static boolean loaded = false;

    static {
        loadLibrary();
    }

    private static synchronized void loadLibrary() {
        if (!loaded) {
            NativeLibraryLoader.loadJNILibrary();
            loaded = true;
        }
    }

    // Compile sketch
    public static native String compile(String sketchPath, String fqbn);

    // Upload compiled hex or directory
    public static native String upload(String sketchPath, String fqbn, String port);

    // Execute any CLI command
    public static native String exec(String command);
}
