package com.example.sawa

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.ImageFormat
import android.graphics.Matrix
import android.graphics.Rect
import android.graphics.YuvImage
import androidx.annotation.NonNull
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarker
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarkerResult
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

class MainActivity : FlutterActivity() {
    private val CHANNEL = "mindora/hand_tracking"
    private var handLandmarker: HandLandmarker? = null
    private val executor = Executors.newSingleThreadExecutor()
    private val isProcessing = AtomicBoolean(false)

    private var isMediaPipeAvailable: Boolean = true
    private var initErrorMessage: String? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Auto-init MediaPipe at startup for early diagnostics
        executor.execute {
            try {
                initMediaPipe()
            } catch (_: Throwable) {}
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isSupported" -> {
                    result.success(true) // Always report supported; let init errors surface naturally
                }
                "initLandmarker" -> {
                    android.util.Log.e("MindoraMovement", "--> MethodChannel initLandmarker requested")
                    executor.execute {
                        try {
                            initMediaPipe()
                            val success = handLandmarker != null
                            android.util.Log.e("MindoraMovement", "--> MediaPipe init result: $success, handLandmarker=$handLandmarker")
                            activity.runOnUiThread { result.success(success) }
                        } catch (t: Throwable) {
                            val errorMsg = "${t.javaClass.name}: ${t.message}"
                            android.util.Log.e("MindoraMovement", "--> MediaPipe init EXCEPTION: $errorMsg", t)
                            initErrorMessage = errorMsg
                            activity.runOnUiThread { result.success(false) }
                        }
                    }
                }
                "getInitError" -> {
                    result.success(initErrorMessage)
                }
                "readDiagFile" -> {
                    try {
                        val diagFile = java.io.File(context.cacheDir, "mediapipe_diag.txt")
                        val content = if (diagFile.exists()) diagFile.readText() else "diag file not found at ${diagFile.absolutePath}"
                        result.success(content)
                    } catch (e: Throwable) {
                        result.success("Error reading diag: ${e.message}")
                    }
                }
                "processYuvFrame" -> {
                    if (isProcessing.get()) {
                        result.success(mapOf("isTracked" to false, "reason" to "busy"))
                        return@setMethodCallHandler
                    }

                    val y = call.argument<ByteArray>("y")
                    val u = call.argument<ByteArray>("u")
                    val v = call.argument<ByteArray>("v")
                    val width = call.argument<Int>("width") ?: 0
                    val height = call.argument<Int>("height") ?: 0
                    val yRowStride = call.argument<Int>("yRowStride") ?: width
                    val uvRowStride = call.argument<Int>("uvRowStride") ?: width
                    val uvPixelStride = call.argument<Int>("uvPixelStride") ?: 1
                    val rotation = call.argument<Int>("rotation") ?: 0
                    val isFront = call.argument<Boolean>("isFront") ?: true

                    if (y == null || u == null || v == null || width <= 0 || height <= 0) {
                        result.success(mapOf("isTracked" to false, "reason" to "invalid_arguments"))
                        return@setMethodCallHandler
                    }

                    isProcessing.set(true)
                    executor.execute {
                        try {
                            if (handLandmarker == null) {
                                try {
                                    initMediaPipe()
                                } catch (initErr: Throwable) {
                                    initErrorMessage = "${initErr.javaClass.name}: ${initErr.message}"
                                    android.util.Log.e("MindoraMovement", "processYuvFrame inline init FAILED: $initErrorMessage", initErr)
                                    activity.runOnUiThread {
                                        result.success(mapOf("isTracked" to false, "reason" to "init_failed", "error" to initErrorMessage))
                                    }
                                    return@execute
                                }
                            }

                            val trackingResult = detectHand(
                                y, u, v, width, height, yRowStride, uvRowStride, uvPixelStride, rotation, isFront
                            )
                            activity.runOnUiThread { result.success(trackingResult) }
                        } catch (t: Throwable) {
                            android.util.Log.e("MindoraMovement", "processYuvFrame EXCEPTION: ${t.javaClass.name}: ${t.message}", t)
                            activity.runOnUiThread {
                                result.success(mapOf("isTracked" to false, "error" to t.message))
                            }
                        } finally {
                            isProcessing.set(false)
                        }
                    }
                }
                "closeLandmarker" -> {
                    executor.execute {
                        try {
                            handLandmarker?.close()
                        } catch (_: Throwable) {}
                        handLandmarker = null
                        activity.runOnUiThread { result.success(true) }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun initMediaPipe() {
        if (handLandmarker != null) return

        val assetName = "hand_landmarker.task"
        val diagFile = java.io.File(context.cacheDir, "mediapipe_diag.txt")

        fun writeLog(msg: String) {
            try { diagFile.appendText("[${System.currentTimeMillis()}] $msg\n") } catch (_: Throwable) {}
            android.util.Log.e("MindoraMovement", msg)
        }

        writeLog("=== initMediaPipe START ===")

        // Pre-flight: verify asset is accessible
        try {
            val assetFd = context.assets.openFd(assetName)
            writeLog("Asset OK: length=${assetFd.length}, startOffset=${assetFd.startOffset}")
            assetFd.close()
        } catch (e: Throwable) {
            writeLog("Asset pre-flight FAILED: ${e.javaClass.name}: ${e.message}")
            initErrorMessage = "Asset not accessible: ${e.message}"

            // Fallback: load via InputStream → ByteBuffer
            try {
                writeLog("Trying fallback: InputStream -> ByteBuffer...")
                val inputStream = context.assets.open(assetName)
                val modelBytes = inputStream.readBytes()
                inputStream.close()
                writeLog("Model bytes loaded: ${modelBytes.size}")

                val buffer = java.nio.ByteBuffer.allocateDirect(modelBytes.size)
                buffer.put(modelBytes)
                buffer.rewind()

                val baseOptions = BaseOptions.builder().setModelAssetBuffer(buffer).build()
                val options = HandLandmarker.HandLandmarkerOptions.builder()
                    .setBaseOptions(baseOptions)
                    .setMinHandDetectionConfidence(0.5f)
                    .setMinTrackingConfidence(0.5f)
                    .setMinHandPresenceConfidence(0.5f)
                    .setNumHands(1)
                    .setRunningMode(RunningMode.IMAGE)
                    .build()

                handLandmarker = HandLandmarker.createFromOptions(context, options)
                writeLog("Fallback ByteBuffer init SUCCESS! lm=$handLandmarker")
                initErrorMessage = null
                return
            } catch (fallbackErr: Throwable) {
                writeLog("Fallback ALSO FAILED: ${fallbackErr.javaClass.name}: ${fallbackErr.message}")
                initErrorMessage = "Both paths failed. openFd: ${e.message} | ByteBuffer: ${fallbackErr.message}"
                throw fallbackErr
            }
        }

        // Primary path: memory-mapped asset (requires noCompress)
        try {
            val baseOptions = BaseOptions.builder().setModelAssetPath(assetName).build()
            val options = HandLandmarker.HandLandmarkerOptions.builder()
                .setBaseOptions(baseOptions)
                .setMinHandDetectionConfidence(0.5f)
                .setMinTrackingConfidence(0.5f)
                .setMinHandPresenceConfidence(0.5f)
                .setNumHands(1)
                .setRunningMode(RunningMode.IMAGE)
                .build()

            handLandmarker = HandLandmarker.createFromOptions(context, options)
            writeLog("Primary AssetPath init SUCCESS! lm=$handLandmarker")
        } catch (e: Throwable) {
            writeLog("Primary AssetPath FAILED: ${e.javaClass.name}: ${e.message}")
            initErrorMessage = "AssetPath failed: ${e.message}"
            throw e
        }
    }


    private fun detectHand(
        y: ByteArray, u: ByteArray, v: ByteArray,
        width: Int, height: Int,
        yRowStride: Int, uvRowStride: Int, uvPixelStride: Int,
        rotation: Int, isFront: Boolean
    ): Map<String, Any> {
        val landmarker = handLandmarker
        if (landmarker == null) {
            android.util.Log.w("MindoraMovement", "detectHand: handLandmarker is null!")
            return mapOf("isTracked" to false, "reason" to "null_landmarker")
        }

        // 1. Convert YUV to NV21 byte array
        val nv21 = ByteArray(width * height * 3 / 2)
        var pos = 0
        if (yRowStride == width) {
            System.arraycopy(y, 0, nv21, 0, width * height)
            pos = width * height
        } else {
            for (row in 0 until height) {
                System.arraycopy(y, row * yRowStride, nv21, pos, width)
                pos += width
            }
        }
        val chromaHeight = height / 2
        val chromaWidth = width / 2
        for (row in 0 until chromaHeight) {
            for (col in 0 until chromaWidth) {
                val uIdx = row * uvRowStride + col * uvPixelStride
                val vIdx = row * uvRowStride + col * uvPixelStride
                if (pos + 1 < nv21.size && vIdx < v.size && uIdx < u.size) {
                    nv21[pos++] = v[vIdx]
                    nv21[pos++] = u[uIdx]
                }
            }
        }

        // 2. Compress NV21 to Bitmap
        val yuvImage = YuvImage(nv21, ImageFormat.NV21, width, height, null)
        val out = ByteArrayOutputStream()
        yuvImage.compressToJpeg(Rect(0, 0, width, height), 70, out)
        val rawBitmap = BitmapFactory.decodeByteArray(out.toByteArray(), 0, out.size())
        if (rawBitmap == null) {
            android.util.Log.w("MindoraMovement", "detectHand: rawBitmap decoding failed")
            return mapOf("isTracked" to false, "reason" to "bitmap_decode_failed")
        }

        // 3. Rotate & Mirror
        val matrix = Matrix()
        matrix.postRotate(rotation.toFloat())
        if (isFront) {
            // Mirror horizontally so moving right moves right on screen
            matrix.postScale(-1f, 1f)
        }
        val rotatedBitmap = Bitmap.createBitmap(rawBitmap, 0, 0, rawBitmap.width, rawBitmap.height, matrix, true)

        // 4. Run MediaPipe Landmarker
        val mpImage = BitmapImageBuilder(rotatedBitmap).build()
        val result: HandLandmarkerResult = landmarker.detect(mpImage)

        val landmarks = result.landmarks()
        if (landmarks.isEmpty() || landmarks[0].isEmpty()) {
            android.util.Log.i("MindoraMovement", "detect: no hand found (rot: ${rotatedBitmap.width}x${rotatedBitmap.height})")
            return mapOf("isTracked" to false, "reason" to "no_hand")
        }

        val hand = landmarks[0]
        // MediaPipe Landmark 8 = Index Finger Tip
        // MediaPipe Landmark 9 = Middle Finger MCP / Base of Hand
        val landmark8 = if (hand.size > 8) hand[8] else null
        val landmark9 = if (hand.size > 9) hand[9] else null

        if (landmark8 == null && landmark9 == null) {
            android.util.Log.w("MindoraMovement", "detect: hand found but landmarks 8 and 9 are null")
            return mapOf("isTracked" to false, "reason" to "missing_landmarks")
        }

        // Confidence from handedness score
        val handedness = result.handedness()
        val confidence = if (handedness.isNotEmpty() && handedness[0].isNotEmpty()) {
            handedness[0][0].score().toDouble()
        } else {
            0.85
        }

        // Check if landmark 8 is reliable; if not, fallback to landmark 9
        val chosenLandmark = if (landmark8 != null && (!landmark8.presence().isPresent || landmark8.presence().get() >= 0.5f)) {
            8 to landmark8
        } else if (landmark9 != null) {
            9 to landmark9
        } else {
            8 to landmark8!!
        }

        val lm = chosenLandmark.second
        val lmIndex = chosenLandmark.first

        android.util.Log.i(
            "MindoraMovement",
            "MediaPipe: TRACKED! chosen=$lmIndex x=${String.format("%.3f", lm.x())} y=${String.format("%.3f", lm.y())} conf=${String.format("%.2f", confidence)} lm8=(${landmark8?.x()?.let { String.format("%.3f", it) }}, ${landmark8?.y()?.let { String.format("%.3f", it) }}) lm9=(${landmark9?.x()?.let { String.format("%.3f", it) }}, ${landmark9?.y()?.let { String.format("%.3f", it) }}) bmp=${rotatedBitmap.width}x${rotatedBitmap.height}"
        )

        return mapOf(
            "isTracked" to true,
            "x" to lm.x().toDouble(),
            "y" to lm.y().toDouble(),
            "confidence" to confidence,
            "landmarkUsed" to lmIndex,
            "landmark8_x" to (landmark8?.x()?.toDouble() ?: 0.0),
            "landmark8_y" to (landmark8?.y()?.toDouble() ?: 0.0),
            "landmark9_x" to (landmark9?.x()?.toDouble() ?: 0.0),
            "landmark9_y" to (landmark9?.y()?.toDouble() ?: 0.0)
        )
    }
}
