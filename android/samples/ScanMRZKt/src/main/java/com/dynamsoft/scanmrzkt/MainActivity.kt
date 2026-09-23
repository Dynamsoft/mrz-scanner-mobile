package com.dynamsoft.scanmrzkt

import android.content.Intent
import android.os.Bundle
import android.view.View

import androidx.activity.enableEdgeToEdge
import androidx.activity.result.ActivityResultLauncher
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat

import com.dynamsoft.mrzscannerbundle.ui.MRZScannerActivity
import com.dynamsoft.mrzscannerbundle.ui.MRZScannerConfig

class MainActivity : AppCompatActivity() {

    private lateinit var launcher: ActivityResultLauncher<MRZScannerConfig>
    private val config = MRZScannerConfig()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContentView(R.layout.activity_main)
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main)) { v, insets ->
            val systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars())
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom)
            insets
        }

        // A trial license, so it needs a network connection. Request your own at
        // https://www.dynamsoft.com/customer/license/trialLicense?product=mrz&utm_source=samples&package=android
        config.license = "DLS2eyJvcmdhbml6YXRpb25JRCI6IjIwMDAwMSJ9"

        // Every setting below is commented out at the opposite of its default — uncomment to try.

        // Restrict recognition to one document family. Default is DT_ALL, which reads both.
        // Needs: import com.dynamsoft.mrzscannerbundle.ui.EnumDocumentType
        //config.documentType = EnumDocumentType.DT_PASSPORT
        // Your own Capture Vision template (path or inline JSON); outranks the document type.
        //config.templateFile = "MyTemplate.json"

        // Scanner controls. Every one of these is visible by default.
        //config.isCloseButtonVisible = false        // Leaves no way out of the scanner.
        //config.isTorchButtonVisible = false        // Hides the torch toggle.
        //config.isCameraToggleButtonVisible = false // Hides the front/back camera toggle.
        //config.isBeepButtonVisible = false         // Hides the beep toggle.
        //config.isVibrateButtonVisible = false      // Hides the vibrate toggle.
        //config.isFormatSelectorVisible = false     // Hides the ID / Both / Passport selector.
        //config.isGuideFrameVisible = false         // Hides the guide frame and its prompt.

        // Both off by default; the buttons above toggle them, so this is just the opening state.
        //config.isBeepEnabled = true
        //config.isVibrateEnabled = true

        // Crops come back by default, the full camera frame does not.
        //config.isReturnDocumentImage = false
        //config.isReturnPortraitImage = false
        //config.isReturnOriginalImage = true

        // Suppress the scanner's own permission dialog; either way it arrives as RS_EXCEPTION.
        //config.isCameraPermissionPromptEnabled = false

        launcher = registerForActivityResult(MRZScannerActivity.ResultContract()) { result ->
            // Hand the result to ResultActivity.
            val intent = Intent(this, ResultActivity::class.java)
            intent.putExtra(ResultActivity.EXTRA_RESULT, result)
            startActivityForResult(intent, ResultActivity.REQUEST_CODE)
        }

        findViewById<View>(R.id.btn_start).setOnClickListener { launcher.launch(config) }
    }

    // Deprecated, but kept so the hand-off mirrors the Java sample one-for-one.
    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == ResultActivity.REQUEST_CODE && resultCode == RESULT_OK) {
            // Act on what ResultActivity sent back.
            val action = data?.getIntExtra(ResultActivity.EXTRA_ACTION, ResultActivity.ACTION_RETURN_HOME)
                ?: ResultActivity.ACTION_RETURN_HOME
            if (action == ResultActivity.ACTION_RESCAN) {
                launcher.launch(config)
            } else if (action == ResultActivity.ACTION_RETURN_HOME) {
                // Do nothing, this activity is Home.
            }
        }
    }
}
