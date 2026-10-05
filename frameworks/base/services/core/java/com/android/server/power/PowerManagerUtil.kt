package com.android.server.power

import android.util.Slog
import java.io.File
import java.io.FileNotFoundException
import java.io.IOException

/**
 * Utility class to handle low-level file writing safely in system services.
 */
object PowerManagerUtil {
    private const val TAG = "PowerManagerUtil"

    /**
     * Safely writes an integer value to a sysfs node path.
     * Silently ignores and handles missing files (ENOENT) so it doesn't crash 
     * or flood logcat with stack traces when a hardware node isn't present.
     */
    @JvmStatic
    fun fileWriteInt(filePath: String, value: Int) {
        val file = File(filePath)
        
        // Check if the file/node exists before attempting to write
        if (!file.exists()) {
            return
        }

        try {
            file.writeText(value.toString())
        } catch (e: FileNotFoundException) {
            Slog.w(TAG, "File not found: $filePath", e)
        } catch (e: IOException) {
            Slog.w(TAG, "Failed to write $value to $filePath", e)
        }
    }

    /**
     * Overload if a String value needs to be written safely.
     */
    @JvmStatic
    fun fileWriteString(filePath: String, value: String) {
        val file = File(filePath)
        if (!file.exists()) {
            return
        }

        try {
            file.writeText(value)
        } catch (e: IOException) {
            Slog.w(TAG, "Failed to write string to $filePath", e)
        }
    }
}
