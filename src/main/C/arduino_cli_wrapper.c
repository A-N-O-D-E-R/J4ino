#include <jni.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef _WIN32
#include <windows.h>
#else
#include <unistd.h>
#include <fcntl.h>
#endif

#include "com_anode_arduino_jni_ArduinoCLINative.h"


// Cross-platform process runner
char* run_process(const char* cmd) {
    FILE* pipe = popen(cmd, "r");
    if (!pipe) return strdup("ERROR: cannot run command");

    char buffer[2048];
    char* result = calloc(1, 1);

    while (fgets(buffer, sizeof(buffer), pipe)) {
        result = realloc(result, strlen(result) + strlen(buffer) + 1);
        strcat(result, buffer);
    }

    pclose(pipe);
    return result;
}


JNIEXPORT jstring JNICALL Java_com_anode_arduino_jni_ArduinoCLINative_compile
  (JNIEnv* env, jclass clazz, jstring jSketch, jstring jFqbn)
{
    const char* sketch = (*env)->GetStringUTFChars(env, jSketch, 0);
    const char* fqbn   = (*env)->GetStringUTFChars(env, jFqbn, 0);

    char cmd[1024];
    snprintf(cmd, sizeof(cmd), "arduino-cli compile --fqbn %s %s", fqbn, sketch);

    char* output = run_process(cmd);
    jstring result = (*env)->NewStringUTF(env, output);

    free(output);
    (*env)->ReleaseStringUTFChars(env, jSketch, sketch);
    (*env)->ReleaseStringUTFChars(env, jFqbn, fqbn);

    return result;
}



JNIEXPORT jstring JNICALL Java_com_anode_arduino_jni_ArduinoCLINative_upload
  (JNIEnv* env, jclass clazz, jstring jSketch, jstring jFqbn, jstring jPort)
{
    const char* sketch = (*env)->GetStringUTFChars(env, jSketch, 0);
    const char* fqbn   = (*env)->GetStringUTFChars(env, jFqbn, 0);
    const char* port   = (*env)->GetStringUTFChars(env, jPort, 0);

    char cmd[1024];
    snprintf(cmd, sizeof(cmd), "arduino-cli upload -p %s --fqbn %s %s", port, fqbn, sketch);

    char* output = run_process(cmd);
    jstring result = (*env)->NewStringUTF(env, output);

    free(output);
    (*env)->ReleaseStringUTFChars(env, jSketch, sketch);
    (*env)->ReleaseStringUTFChars(env, jFqbn, fqbn);
    (*env)->ReleaseStringUTFChars(env, jPort, port);

    return result;
}



JNIEXPORT jstring JNICALL Java_com_anode_arduino_jni_ArduinoCLINative_exec
  (JNIEnv* env, jclass clazz, jstring jCmd)
{
    const char* cmd = (*env)->GetStringUTFChars(env, jCmd, 0);

    char* output = run_process(cmd);
    jstring result = (*env)->NewStringUTF(env, output);

    free(output);
    (*env)->ReleaseStringUTFChars(env, jCmd, cmd);

    return result;
}
