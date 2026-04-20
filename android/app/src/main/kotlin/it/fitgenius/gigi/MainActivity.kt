package it.fitgenius.gigi

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.os.Build
import android.view.View
import android.widget.RemoteViews
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.math.roundToInt

class MainActivity : FlutterActivity() {
    private val channelName = "it.fitgenius.gigi/workout_notification"
    private val notificationId = 7201
    private val notificationChannelId = "workout_lock_screen"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "updateWorkoutNotification" -> {
                        val payload = call.arguments as? Map<*, *>
                        if (payload == null) {
                            result.error("bad_args", "Missing workout payload", null)
                            return@setMethodCallHandler
                        }
                        updateWorkoutNotification(payload)
                        result.success(null)
                    }
                    "clearWorkoutNotification" -> {
                        clearWorkoutNotification()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun updateWorkoutNotification(payload: Map<*, *>) {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        ensureNotificationChannel(manager)

        val currentExercise = payload["currentExerciseName"] as? String ?: "Allenamento"
        val workoutName = payload["workoutName"] as? String ?: "GIGI"
        val currentSetNumber = (payload["currentSetNumber"] as? Number)?.toInt() ?: 1
        val currentSetTotal = (payload["currentSetTotal"] as? Number)?.toInt() ?: 1
        val currentTargetReps = payload["currentTargetReps"] as? String
        val nextExercise = payload["nextExerciseName"] as? String
        val nextSetNumber = (payload["nextSetNumber"] as? Number)?.toInt()
        val nextSetTotal = (payload["nextSetTotal"] as? Number)?.toInt()
        val nextTargetReps = payload["nextTargetReps"] as? String
        val isResting = payload["isResting"] as? Boolean ?: false
        val restRemainingSeconds = (payload["restRemainingSeconds"] as? Number)?.toInt()
        val primaryMuscles = stringList(payload["currentMuscleGroups"])
        val secondaryMuscles = stringList(payload["currentSecondaryMuscleGroups"])

        val remoteViews = RemoteViews(packageName, R.layout.workout_lock_screen_notification)
        remoteViews.setTextViewText(R.id.workout_name, workoutName)
        remoteViews.setTextViewText(R.id.current_exercise, currentExercise)
        remoteViews.setTextViewText(R.id.current_set, "Set $currentSetNumber/$currentSetTotal")
        if (currentTargetReps.isNullOrBlank()) {
            remoteViews.setViewVisibility(R.id.current_reps, View.GONE)
        } else {
            remoteViews.setViewVisibility(R.id.current_reps, View.VISIBLE)
            remoteViews.setTextViewText(R.id.current_reps, "$currentTargetReps reps")
        }

        if (isResting && restRemainingSeconds != null) {
            remoteViews.setViewVisibility(R.id.rest_timer, View.VISIBLE)
            remoteViews.setTextViewText(R.id.rest_timer, formatSeconds(restRemainingSeconds))
        } else {
            remoteViews.setViewVisibility(R.id.rest_timer, View.GONE)
        }

        val nextLine = if (nextExercise != null && nextSetNumber != null && nextSetTotal != null) {
            val reps = if (nextTargetReps.isNullOrBlank()) "" else " • $nextTargetReps reps"
            "Prossima: $nextExercise • Set $nextSetNumber/$nextSetTotal$reps"
        } else {
            "Prossima: fine allenamento"
        }
        remoteViews.setTextViewText(R.id.next_set, nextLine)
        remoteViews.setImageViewBitmap(R.id.body_image, createBodyBitmap(primaryMuscles, secondaryMuscles))

        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val title = if (isResting && restRemainingSeconds != null) {
            "Recupero: ${formatSeconds(restRemainingSeconds)}"
        } else {
            "$currentExercise • Set $currentSetNumber/$currentSetTotal"
        }

        val notification = Notification.Builder(this, notificationChannelId)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(nextLine)
            .setCustomContentView(remoteViews)
            .setCustomBigContentView(remoteViews)
            .setStyle(Notification.DecoratedCustomViewStyle())
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setShowWhen(false)
            .setSilent(true)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setCategory(Notification.CATEGORY_PROGRESS)
            .build()

        manager.notify(notificationId, notification)
    }

    private fun clearWorkoutNotification() {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.cancel(notificationId)
    }

    private fun ensureNotificationChannel(manager: NotificationManager) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            notificationChannelId,
            "Allenamento in corso",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "Mostra esercizio corrente, corpo anatomico e prossima serie."
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            setSound(null, null)
            enableVibration(false)
        }
        manager.createNotificationChannel(channel)
    }

    private fun stringList(value: Any?): List<String> {
        return (value as? List<*>)?.mapNotNull { it?.toString() } ?: emptyList()
    }

    private fun formatSeconds(seconds: Int): String {
        val minutes = seconds / 60
        val remaining = seconds % 60
        return "$minutes:${remaining.toString().padStart(2, '0')}"
    }

    private fun createBodyBitmap(primaryMuscles: List<String>, secondaryMuscles: List<String>): Bitmap {
        val width = dp(68)
        val height = dp(108)
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)

        paint.color = Color.rgb(25, 25, 28)
        canvas.drawRoundRect(RectF(0f, 0f, width.toFloat(), height.toFloat()), dp(12).toFloat(), dp(12).toFloat(), paint)

        val centerX = width / 2f
        paint.color = baseColor
        canvas.drawCircle(centerX, dp(15).toFloat(), dp(8).toFloat(), paint)

        paint.color = colorFor(listOf("chest", "petto", "back", "schiena", "core", "abs", "addome"), primaryMuscles, secondaryMuscles)
        canvas.drawRoundRect(RectF(centerX - dp(12), dp(27).toFloat(), centerX + dp(12), dp(66).toFloat()), dp(11).toFloat(), dp(11).toFloat(), paint)

        paint.color = colorFor(listOf("shoulders", "spalle", "arms", "biceps", "triceps", "braccia"), primaryMuscles, secondaryMuscles)
        canvas.drawRoundRect(RectF(centerX - dp(30), dp(29).toFloat(), centerX - dp(20), dp(70).toFloat()), dp(5).toFloat(), dp(5).toFloat(), paint)
        canvas.drawRoundRect(RectF(centerX + dp(20), dp(29).toFloat(), centerX + dp(30), dp(70).toFloat()), dp(5).toFloat(), dp(5).toFloat(), paint)

        paint.color = colorFor(listOf("abs", "core", "addome"), primaryMuscles, secondaryMuscles)
        canvas.drawRoundRect(RectF(centerX - dp(9), dp(49).toFloat(), centerX + dp(9), dp(69).toFloat()), dp(8).toFloat(), dp(8).toFloat(), paint)

        paint.color = colorFor(listOf("legs", "quad", "hamstrings", "glutes", "gambe", "glutei", "calves", "polpacci"), primaryMuscles, secondaryMuscles)
        canvas.drawRoundRect(RectF(centerX - dp(14), dp(69).toFloat(), centerX - dp(4), dp(104).toFloat()), dp(5).toFloat(), dp(5).toFloat(), paint)
        canvas.drawRoundRect(RectF(centerX + dp(4), dp(69).toFloat(), centerX + dp(14), dp(104).toFloat()), dp(5).toFloat(), dp(5).toFloat(), paint)

        return bitmap
    }

    private fun colorFor(tokens: List<String>, primaryMuscles: List<String>, secondaryMuscles: List<String>): Int {
        if (containsToken(primaryMuscles, tokens)) return primaryColor
        if (containsToken(secondaryMuscles, tokens)) return secondaryColor
        return baseColor
    }

    private fun containsToken(muscles: List<String>, tokens: List<String>): Boolean {
        return muscles.any { muscle ->
            val normalized = muscle.lowercase()
            tokens.any { token -> normalized.contains(token) }
        }
    }

    private fun dp(value: Int): Int = (value * resources.displayMetrics.density).roundToInt()

    companion object {
        private val primaryColor = Color.rgb(229, 57, 53)
        private val secondaryColor = Color.rgb(239, 154, 154)
        private val baseColor = Color.argb(70, 255, 255, 255)
    }
}
