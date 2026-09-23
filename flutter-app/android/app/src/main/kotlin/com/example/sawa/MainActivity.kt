package com.example.sawa

import android.graphics.Bitmap
import android.graphics.Matrix
import androidx.annotation.NonNull
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarker
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarkerResult
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

class MainActivity : FlutterActivity() {
    private val CHANNEL = "mindora/hand_tracking"
    private var handLandmarker: HandLandmarker? = null
    private val executor = Executors.newSingleThreadExecutor()
    private val isProcessing = AtomicBoolean(false)

    // ── Diagnostic instrumentation ────────────────────────────────────────────
    // Rate-limit to ~5 diagnostic logs per second (every 6th frame at ~30fps)
    private var diagFrameCount = 0
    private val DIAG_EVERY_N_FRAMES = 6

    // ── Reusable pixel buffer & Bitmap (eliminates per-frame GC pressure) ───────
    // These are lazily initialised on the first frame and reused thereafter.
    // Access is safe because detectHand() is always called from the single executor thread.
    private var pixelBuf: IntArray? = null       // ARGB pixels, size = width * height
    private var rawBitmapCache: Bitmap? = null   // Bitmap.Config.ARGB_8888, width x height
    private var rotatedBitmapCache: Bitmap? = null // post-rotation Bitmap, may be transposed
    // ─────────────────────────────────────────────────────────────────────────

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

        val benchmarkReceiver = object : android.content.BroadcastReceiver() {
            override fun onReceive(c: android.content.Context?, intent: android.content.Intent?) {
                when (intent?.action) {
                    "com.example.sawa.BENCHMARK_REPORT" -> {
                        val deviceModel = android.os.Build.MANUFACTURER + " " + android.os.Build.MODEL
                        val androidVer = android.os.Build.VERSION.RELEASE
                        PerformanceBenchmark.logFinalReport("$deviceModel (Android $androidVer)")
                    }
                    "com.example.sawa.BENCHMARK_RESET" -> {
                        PerformanceBenchmark.reset()
                        android.util.Log.i("SAWA_BENCHMARK", "=== BENCHMARK RESET ===")
                    }
                }
            }
        }
        val bFilter = android.content.IntentFilter().apply {
            addAction("com.example.sawa.BENCHMARK_REPORT")
            addAction("com.example.sawa.BENCHMARK_RESET")
        }
        if (android.os.Build.VERSION.SDK_INT >= 33) {
            registerReceiver(benchmarkReceiver, bFilter, android.content.Context.RECEIVER_EXPORTED)
        } else {
            registerReceiver(benchmarkReceiver, bFilter)
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
                        PerformanceBenchmark.onFrameDropped() // BENCHMARK: count drop
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

                // ── Benchmark control (non-production) ────────────────────────
                "benchmarkStart" -> {
                    PerformanceBenchmark.reset()
                    PerformanceBenchmark.BENCHMARK_MODE = true
                    android.util.Log.i("SAWA_BENCHMARK", "=== BENCHMARK STARTED ===")
                    result.success(true)
                }
                "benchmarkStop" -> {
                    PerformanceBenchmark.BENCHMARK_MODE = false
                    val deviceModel = android.os.Build.MANUFACTURER + " " + android.os.Build.MODEL
                    val androidVer = android.os.Build.VERSION.RELEASE
                    PerformanceBenchmark.logFinalReport("$deviceModel (Android $androidVer)")
                    val r = PerformanceBenchmark.computeResult()
                    result.success(mapOf(
                        "sampleCount"       to r.sampleCount,
                        "avgLatencyMs"      to r.avgLatencyMs,
                        "medianLatencyMs"   to r.medianLatencyMs,
                        "p95LatencyMs"      to r.p95LatencyMs,
                        "minLatencyMs"      to r.minLatencyMs,
                        "maxLatencyMs"      to r.maxLatencyMs,
                        "samplesOver100ms"  to r.samplesOver100ms,
                        "avgFps"            to r.avgFps,
                        "medianFps"         to r.medianFps,
                        "p5Fps"             to r.p95Fps,
                        "acceptedFrames"    to r.acceptedFrames,
                        "droppedFrames"     to r.droppedFrames,
                        "totalAttempts"     to r.totalAttempts,
                        "infOnlyAvgMs"      to r.inferenceOnlyAvgMs,
                        "infOnlyP95Ms"      to r.inferenceOnlyP95Ms
                    ))
                }
                "benchmarkReset" -> {
                    PerformanceBenchmark.reset()
                    result.success(true)
                }
                // ──────────────────────────────────────────────────────────────
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
        // BENCHMARK: record frame acceptance and start wall-clock timer
        val benchStart = PerformanceBenchmark.onFrameAccepted()
        val landmarker = handLandmarker
        if (landmarker == null) {
            android.util.Log.w("MindoraMovement", "detectHand: handLandmarker is null!")
            return mapOf("isTracked" to false, "reason" to "null_landmarker")
        }

        // ── 1. Direct YUV_420_888 → ARGB_8888 Bitmap (no JPEG round-trip) ──────────
        // Reuse pixel buffer and Bitmap to avoid per-frame allocation / GC pressure.
        val numPixels = width * height
        val pixels = pixelBuf?.takeIf { it.size == numPixels }
            ?: IntArray(numPixels).also { pixelBuf = it }
        val rawBitmap = rawBitmapCache?.takeIf { it.width == width && it.height == height }
            ?: Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888).also { rawBitmapCache = it }

        // YCbCr → ARGB conversion: BT.601 limited range
        // Each U/V sample covers a 2×2 luma block (4:2:0 sub-sampling).
        for (row in 0 until height) {
            val yBase  = row * yRowStride
            val uvRow  = (row shr 1) * uvRowStride
            val pBase  = row * width
            for (col in 0 until width) {
                val yVal = (y[yBase + col].toInt() and 0xFF) - 16
                val uvCol = (col shr 1) * uvPixelStride
                val uVal  = (u[uvRow + uvCol].toInt() and 0xFF) - 128
                val vVal  = (v[uvRow + uvCol].toInt() and 0xFF) - 128

                // BT.601 coefficients scaled ×1024 for integer arithmetic
                val r = (1192 * yVal + 1634 * vVal) shr 10
                val g = (1192 * yVal -  833 * vVal - 400 * uVal) shr 10
                val b = (1192 * yVal + 2066 * uVal) shr 10

                pixels[pBase + col] = (0xFF shl 24) or
                    (r.coerceIn(0, 255) shl 16) or
                    (g.coerceIn(0, 255) shl 8)  or
                    b.coerceIn(0, 255)
            }
        }
        rawBitmap.setPixels(pixels, 0, width, 0, 0, width, height)

        // 3. Rotate ONLY — no horizontal mirror here.
        // The canonical front-camera x-flip (x = 1.0 - x) is applied once in
        // hand_tracker_service.dart after receiving the landmarks, keeping the
        // visual CameraPreview and the landmark coordinate space in sync.
        //
        // Optimisation: compute expected rotated dimensions and reuse an existing
        // Bitmap of the same size to avoid GC-heavy createBitmap() every frame.
        val isTransposed = rotation == 90 || rotation == 270
        val rotW = if (isTransposed) height else width
        val rotH = if (isTransposed) width  else height
        val rotatedBitmap = rotatedBitmapCache
            ?.takeIf { it.width == rotW && it.height == rotH && !it.isRecycled }
            ?: Bitmap.createBitmap(rotW, rotH, Bitmap.Config.ARGB_8888)
                .also { rotatedBitmapCache = it }

        // Draw rawBitmap into rotatedBitmap using the rotation matrix
        val canvas = android.graphics.Canvas(rotatedBitmap)
        val matrix = Matrix()
        matrix.postRotate(rotation.toFloat(), rawBitmap.width / 2f, rawBitmap.height / 2f)
        matrix.postTranslate((rotW - rawBitmap.width) / 2f, (rotH - rawBitmap.height) / 2f)
        canvas.drawBitmap(rawBitmap, matrix, null)

        // 4. Run MediaPipe Landmarker
        val mpImage = BitmapImageBuilder(rotatedBitmap).build()

        // ── DIAG: pre-MediaPipe ──────────────────────────────────────────────
        diagFrameCount++
        val isDiagFrame = (diagFrameCount % DIAG_EVERY_N_FRAMES == 0)
        val diagStartMs = if (isDiagFrame) System.currentTimeMillis() else 0L
        if (isDiagFrame) {
            android.util.Log.i(
                "[COORD_DIAG]",
                "PRE_MP | rotation=$rotation | isFront=$isFront | " +
                "yuv=${width}x${height} | bitmap(raw)=${rawBitmap.width}x${rawBitmap.height} | " +
                "bitmap(rotated)=${rotatedBitmap.width}x${rotatedBitmap.height}"
            )
        }
        // ────────────────────────────────────────────────────────────────────

        // BENCHMARK: time MediaPipe inference call alone
        val inferStart = PerformanceBenchmark.startInference()
        val result: HandLandmarkerResult = landmarker.detect(mpImage)
        PerformanceBenchmark.recordInference(inferStart)

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

        // ── DIAG: post-MediaPipe raw result + processing time ──────────────────
        if (isDiagFrame) {
            val processingMs = System.currentTimeMillis() - diagStartMs
            android.util.Log.i(
                "[COORD_DIAG]",
                "POST_MP | chosen=lm$lmIndex | " +
                "RAW_X=${String.format("%.4f", lm.x())} | RAW_Y=${String.format("%.4f", lm.y())} | " +
                "processing_ms=${processingMs}ms | " +
                "lm8_raw=(${String.format("%.4f", landmark8?.x() ?: -1f)}, ${String.format("%.4f", landmark8?.y() ?: -1f)}) | " +
                "lm9_raw=(${String.format("%.4f", landmark9?.x() ?: -1f)}, ${String.format("%.4f", landmark9?.y() ?: -1f)})"
            )
        }
        // ────────────────────────────────────────────────────────────────────

        val finalResult = mapOf(
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
        // BENCHMARK: record total detectHand() duration
        PerformanceBenchmark.recordLatency(benchStart)
        return finalResult
    }
}
