package com.example.sawa

import android.util.Log
import java.util.concurrent.ConcurrentLinkedQueue
import kotlin.math.sqrt

/**
 * PerformanceBenchmark – Non-invasive instrumentation for the SAWA hand-tracking pipeline.
 *
 * Measures:
 *   A. MediaPipe inference latency:
 *      Camera frame received by Dart → processYuvFrame MethodChannel call arrives → detectHand()
 *      begins → MediaPipe HandLandmarker.detect() completes → result returned.
 *
 *   B. Full on-device processing latency (same boundary, from native side):
 *      Includes YUV→NV21 conversion, JPEG compress, Bitmap decode, rotation, MediaPipe detect.
 *      This is what we CAN measure: the entire time detectHand() spends on-device.
 *
 *   C. Frame throughput (FPS):
 *      Derived from the wall-clock timestamps at which each frame *starts* processing.
 *      Divided into: accepted frames (sent to MediaPipe) vs. dropped frames (busy / throttled).
 *
 * Metric naming: "End-to-End On-Device Processing Latency"
 *   = time from detectHand() entry to return, measured on the executor thread.
 *   This is the metric we can honestly claim as "on-device processing latency".
 *   It does NOT include Flutter MethodChannel serialization overhead (~2-5ms typical).
 *
 * To activate: set BENCHMARK_MODE = true in MainActivity before benchmarking.
 * To deactivate: set BENCHMARK_MODE = false (default) for production builds.
 */
object PerformanceBenchmark {

    private const val TAG = "SAWA_BENCHMARK"

    /** Set to true to enable timing collection. false = zero overhead in production. */
    @Volatile
    var BENCHMARK_MODE = true

    // ── Latency samples (detectHand wall-clock duration in ms) ─────────────────
    private val latencySamples = ConcurrentLinkedQueue<Long>()

    // ── FPS tracking (wall-clock ms at frame acceptance) ───────────────────────
    private val frameTimestamps = ConcurrentLinkedQueue<Long>()
    private var droppedFrameCount = 0L
    private var totalFrameAttempts = 0L

    // ── MediaPipe-only inference timing ─────────────────────────────────────────
    private val inferenceOnlySamples = ConcurrentLinkedQueue<Long>()

    // ── Results snapshot ────────────────────────────────────────────────────────
    data class BenchmarkResult(
        val sampleCount: Int,
        val avgLatencyMs: Double,
        val medianLatencyMs: Double,
        val p95LatencyMs: Double,
        val minLatencyMs: Long,
        val maxLatencyMs: Long,
        val samplesOver100ms: Int,
        val avgFps: Double,
        val medianFps: Double,
        val p95Fps: Double,          // 5th-percentile inter-frame interval → worst FPS
        val acceptedFrames: Long,
        val droppedFrames: Long,
        val totalAttempts: Long,
        val inferenceOnlyAvgMs: Double,
        val inferenceOnlyP95Ms: Double
    )

    // ─────────────────────────────────────────────────────────────────────────────
    // Public API used from MainActivity
    // ─────────────────────────────────────────────────────────────────────────────

    /** Call at the top of detectHand() when a frame is ACCEPTED for processing. */
    fun onFrameAccepted(): Long {
        if (!BENCHMARK_MODE) return 0L
        totalFrameAttempts++
        val now = System.currentTimeMillis()
        frameTimestamps.offer(now)
        // Keep only the last 1000 timestamps for FPS rolling window
        while (frameTimestamps.size > 1000) frameTimestamps.poll()
        return now
    }

    /** Call when a frame was DROPPED (busy / throttled) before reaching detectHand(). */
    fun onFrameDropped() {
        if (!BENCHMARK_MODE) return
        totalFrameAttempts++
        droppedFrameCount++
    }

    /** Mark the start of MediaPipe detect() call (inside detectHand, after bitmap prep). */
    fun startInference(): Long {
        return if (BENCHMARK_MODE) System.currentTimeMillis() else 0L
    }

    /** Record the MediaPipe-only inference duration. */
    fun recordInference(startMs: Long) {
        if (!BENCHMARK_MODE || startMs == 0L) return
        val elapsed = System.currentTimeMillis() - startMs
        inferenceOnlySamples.offer(elapsed)
        while (inferenceOnlySamples.size > 1000) inferenceOnlySamples.poll()
    }

    /** Record total detectHand() duration (YUV→bitmap + MediaPipe + result packing). */
    fun recordLatency(startMs: Long) {
        if (!BENCHMARK_MODE || startMs == 0L) return
        val elapsed = System.currentTimeMillis() - startMs
        latencySamples.offer(elapsed)
        while (latencySamples.size > 1000) latencySamples.poll()

        // Periodic console logging every 50 frames
        val count = latencySamples.size
        if (count > 0 && count % 50 == 0) {
            logInterimStats(count, elapsed)
        }
    }

    private fun logInterimStats(count: Int, lastMs: Long) {
        val samples = latencySamples.toList().sorted()
        val avg = samples.average()
        val median = percentile(samples, 50.0)
        val p95 = percentile(samples, 95.0)
        val fps = computeCurrentFps()
        Log.i(TAG, "── Interim [$count frames] ──  " +
                "avg=${avg.toInt()}ms  median=${median.toInt()}ms  p95=${p95.toInt()}ms  " +
                "last=${lastMs}ms  fps=${String.format("%.1f", fps)}")
    }

    /** Compute rolling average FPS from accepted frame timestamps. */
    private fun computeCurrentFps(): Double {
        val ts = frameTimestamps.toList()
        if (ts.size < 2) return 0.0
        val windowMs = ts.last() - ts.first()
        if (windowMs <= 0) return 0.0
        return (ts.size - 1) * 1000.0 / windowMs
    }

    /** Compute per-interval FPS list for median/p95 calculation. */
    private fun computeIntervalFpsList(): List<Double> {
        val ts = frameTimestamps.toList().sorted()
        if (ts.size < 2) return emptyList()
        return ts.zipWithNext { a, b ->
            val interval = b - a
            if (interval > 0) 1000.0 / interval else 0.0
        }.filter { it > 0.0 }
    }

    /** Compute and return a full snapshot of all collected benchmark data. */
    fun computeResult(): BenchmarkResult {
        val latencies = latencySamples.toList().sorted()
        val inferenceSamples = inferenceOnlySamples.toList().sorted()
        val fpsList = computeIntervalFpsList().sorted()

        val avgLat = if (latencies.isNotEmpty()) latencies.average() else 0.0
        val medianLat = if (latencies.isNotEmpty()) percentile(latencies, 50.0) else 0.0
        val p95Lat = if (latencies.isNotEmpty()) percentile(latencies, 95.0) else 0.0
        val minLat = latencies.firstOrNull() ?: 0L
        val maxLat = latencies.lastOrNull() ?: 0L
        val over100ms = latencies.count { it > 100L }

        val avgFps = if (fpsList.isNotEmpty()) fpsList.average() else 0.0
        val medianFps = if (fpsList.isNotEmpty()) percentile(fpsList, 50.0) else 0.0
        // p95 FPS = the WORST 5% of instantaneous FPS (5th percentile of fps values)
        val p95Fps = if (fpsList.isNotEmpty()) percentile(fpsList, 5.0) else 0.0

        val avgInf = if (inferenceSamples.isNotEmpty()) inferenceSamples.average() else 0.0
        val p95Inf = if (inferenceSamples.isNotEmpty()) percentile(inferenceSamples, 95.0) else 0.0

        return BenchmarkResult(
            sampleCount = latencies.size,
            avgLatencyMs = avgLat,
            medianLatencyMs = medianLat,
            p95LatencyMs = p95Lat,
            minLatencyMs = minLat,
            maxLatencyMs = maxLat,
            samplesOver100ms = over100ms,
            avgFps = avgFps,
            medianFps = medianFps,
            p95Fps = p95Fps,
            acceptedFrames = latencies.size.toLong(),
            droppedFrames = droppedFrameCount,
            totalAttempts = totalFrameAttempts,
            inferenceOnlyAvgMs = avgInf,
            inferenceOnlyP95Ms = p95Inf
        )
    }

    /** Log a formatted final report to logcat. Tag: SAWA_BENCHMARK */
    fun logFinalReport(deviceInfo: String = "unknown") {
        val r = computeResult()
        val separator = "═".repeat(60)
        Log.i(TAG, separator)
        Log.i(TAG, "  SAWA PERFORMANCE BENCHMARK FINAL REPORT")
        Log.i(TAG, "  Device: $deviceInfo")
        Log.i(TAG, separator)
        Log.i(TAG, "  LATENCY  (on-device detectHand() wall-clock)")
        Log.i(TAG, "  Samples   : ${r.sampleCount}")
        Log.i(TAG, "  Average   : ${r.avgLatencyMs.toInt()} ms")
        Log.i(TAG, "  Median    : ${r.medianLatencyMs.toInt()} ms")
        Log.i(TAG, "  p95       : ${r.p95LatencyMs.toInt()} ms")
        Log.i(TAG, "  Min       : ${r.minLatencyMs} ms")
        Log.i(TAG, "  Max       : ${r.maxLatencyMs} ms")
        Log.i(TAG, "  >100ms    : ${r.samplesOver100ms} frames (${
            if (r.sampleCount > 0) String.format("%.1f", r.samplesOver100ms * 100.0 / r.sampleCount) else "N/A"
        }%)")
        Log.i(TAG, separator)
        Log.i(TAG, "  MEDIAPIPE INFERENCE ONLY  (detect() call)")
        Log.i(TAG, "  Samples   : ${inferenceOnlySamples.size}")
        Log.i(TAG, "  Average   : ${r.inferenceOnlyAvgMs.toInt()} ms")
        Log.i(TAG, "  p95       : ${r.inferenceOnlyP95Ms.toInt()} ms")
        Log.i(TAG, separator)
        Log.i(TAG, "  THROUGHPUT  (frames processed per second)")
        Log.i(TAG, "  Accepted  : ${r.acceptedFrames}")
        Log.i(TAG, "  Dropped   : ${r.droppedFrames}")
        Log.i(TAG, "  Total att.: ${r.totalAttempts}")
        Log.i(TAG, "  Avg FPS   : ${String.format("%.1f", r.avgFps)}")
        Log.i(TAG, "  Median FPS: ${String.format("%.1f", r.medianFps)}")
        Log.i(TAG, "  p5 FPS    : ${String.format("%.1f", r.p95Fps)}  (worst 5% of intervals)")
        Log.i(TAG, separator)
        Log.i(TAG, "  CLAIM ASSESSMENT")
        val fpsStatus = when {
            r.avgFps >= 15 && r.medianFps >= 15 && r.p95Fps >= 10 -> "VERIFIED (avg+median ≥15, p5 ≥10)"
            r.avgFps >= 15 && r.medianFps >= 15 -> "PARTIALLY VERIFIED (avg+median ≥15, p5 below 10)"
            r.avgFps >= 15 -> "PARTIALLY VERIFIED (avg ≥15 but median below)"
            else -> "NOT VERIFIED (avg ${String.format("%.1f", r.avgFps)} < 15)"
        }
        val latStatus = when {
            r.medianLatencyMs < 100 && r.p95LatencyMs < 100 -> "VERIFIED (median + p95 < 100ms)"
            r.medianLatencyMs < 100 -> "PARTIALLY VERIFIED (median < 100ms, p95 = ${r.p95LatencyMs.toInt()}ms)"
            r.avgLatencyMs < 100 -> "PARTIALLY VERIFIED (avg < 100ms only)"
            else -> "NOT VERIFIED (median ${r.medianLatencyMs.toInt()}ms ≥ 100ms)"
        }
        Log.i(TAG, "  '≥15 FPS'   : $fpsStatus")
        Log.i(TAG, "  '<100ms'    : $latStatus")
        Log.i(TAG, separator)
    }

    /** Reset all collected data. */
    fun reset() {
        latencySamples.clear()
        frameTimestamps.clear()
        inferenceOnlySamples.clear()
        droppedFrameCount = 0L
        totalFrameAttempts = 0L
    }

    // ─────────────────────────────────────────────────────────────────────────────
    // Utility
    // ─────────────────────────────────────────────────────────────────────────────

    @JvmName("percentileLong")
    private fun percentile(sorted: List<Long>, p: Double): Double {
        if (sorted.isEmpty()) return 0.0
        val index = ((p / 100.0) * (sorted.size - 1)).toInt().coerceIn(0, sorted.size - 1)
        return sorted[index].toDouble()
    }

    @JvmName("percentileDouble")
    private fun percentile(sorted: List<Double>, p: Double): Double {
        if (sorted.isEmpty()) return 0.0
        val index = ((p / 100.0) * (sorted.size - 1)).toInt().coerceIn(0, sorted.size - 1)
        return sorted[index]
    }
}
