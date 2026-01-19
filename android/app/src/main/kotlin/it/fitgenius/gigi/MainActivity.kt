package it.fitgenius.gigi

import io.flutter.embedding.android.FlutterActivity
import androidx.activity.EdgeToEdge
import android.os.Bundle

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        EdgeToEdge.enable(this)
    }
}
