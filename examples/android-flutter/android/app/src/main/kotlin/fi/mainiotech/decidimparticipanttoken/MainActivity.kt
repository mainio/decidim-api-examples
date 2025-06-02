package fi.mainiotech.decidimparticipanttoken

import android.content.Intent
import android.graphics.Color
import android.net.Uri
import android.provider.Settings
import androidx.annotation.NonNull
import androidx.browser.customtabs.CustomTabColorSchemeParams
import androidx.browser.trusted.TrustedWebActivityIntentBuilder
import com.google.androidbrowserhelper.trusted.TwaLauncher
import com.google.androidbrowserhelper.trusted.QualityEnforcer
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
  private val CHANNEL = "fi.mainiotech.decidimparticipanttoken/native"
  private var _messenger: MethodChannel? = null
  private var _currentWebActivityUri: Uri? = null;

  override fun onNewIntent(intent: Intent) {
    super.onNewIntent(intent)

    if (intent.getAction() != Intent.ACTION_VIEW) {
      return
    }

    val uri: Uri? = intent.getData()
    if (uri == null) {
      return
    }

    if (uri.getPath() != "/oauth/authorize/native") {
      return
    }

    _currentWebActivityUri = null

    if (uri.getQueryParameter("verify") == "1") {
      // Start the manual verification process by opening the settings view.
      val intent = Intent(
        Settings.ACTION_APP_OPEN_BY_DEFAULT_SETTINGS,
        Uri.parse("package:${getContext().getPackageName()}")
      )
      intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
      startActivity(intent)
    } else {
      _messenger?.invokeMethod("callback", uri.toString())
    }
  }

  override fun onResume() {
    super.onResume()

    if (_currentWebActivityUri != null) {
      val uri = _currentWebActivityUri;
      _currentWebActivityUri = null

      _messenger?.invokeMethod("activityResumedAfterWeb", uri.toString())
    }
  }

  override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)

    _messenger = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

    _messenger?.setMethodCallHandler {
      call, result ->
      if (call.method == "launchUrl") {
        val url = call.arguments as? String
        val uri = Uri.parse(url)

        val colorScheme = CustomTabColorSchemeParams.Builder()
        colorScheme.setNavigationBarColor(Color.parseColor("#60baeb"))
        colorScheme.setToolbarColor(Color.parseColor("#60baeb"))

        val builder = TrustedWebActivityIntentBuilder(uri)
        builder.setDefaultColorSchemeParams(colorScheme.build())

        val launcher = TwaLauncher(this)
        val customTabsCallback = QualityEnforcer()
        launcher.launch(builder, customTabsCallback, null, null)

        _currentWebActivityUri = uri

        result.success(true)
      } else {
        result.notImplemented()
      }
    }
  }
}
