package com.dynamsoft.scanmrzbasickt

import android.os.Bundle
import android.view.View
import android.widget.ImageView
import android.widget.TextView

import androidx.activity.enableEdgeToEdge
import androidx.activity.result.ActivityResultLauncher
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat

import com.dynamsoft.core.basic_structures.CoreException
import com.dynamsoft.core.basic_structures.ImageData
import com.dynamsoft.dcp.EnumValidationStatus
import com.dynamsoft.mrzscannerbundle.ui.MRZScanResult
import com.dynamsoft.mrzscannerbundle.ui.MRZScannerActivity
import com.dynamsoft.mrzscannerbundle.ui.MRZScannerConfig

/** Scans an MRZ and renders the result on this one screen; see ScanMRZ for the fuller app. */
class MainActivity : AppCompatActivity() {

    private val config = MRZScannerConfig()
    private lateinit var launcher: ActivityResultLauncher<MRZScannerConfig>

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContentView(R.layout.activity_main)
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main)) { v, insets ->
            val bars = insets.getInsets(WindowInsetsCompat.Type.systemBars())
            v.setPadding(bars.left, bars.top, bars.right, bars.bottom)
            insets
        }

        // A trial license, so it needs a network connection. Request your own at
        // https://www.dynamsoft.com/customer/license/trialLicense?product=mrz&utm_source=samples&package=android
        config.license = "DLS2eyJvcmdhbml6YXRpb25JRCI6IjIwMDAwMSJ9"

        // The scanner is its own activity, so results arrive via the Activity Result API.
        launcher = registerForActivityResult(MRZScannerActivity.ResultContract()) { result ->
            showResult(result)
        }

        findViewById<View>(R.id.btn_scan).setOnClickListener { launcher.launch(config) }
    }

    /** Renders one of the three result statuses the scanner can come back with. */
    private fun showResult(result: MRZScanResult) {
        val tvStatus = findViewById<TextView>(R.id.tv_status)
        val resultPanel = findViewById<View>(R.id.result_panel)

        if (result.resultStatus == MRZScanResult.EnumResultStatus.RS_CANCELED) {
            // The user closed the scanner. There is no data and nothing went wrong.
            tvStatus.setText(R.string.scan_canceled)
            tvStatus.visibility = View.VISIBLE
            resultPanel.visibility = View.GONE
            return
        }

        if (result.resultStatus == MRZScanResult.EnumResultStatus.RS_EXCEPTION) {
            // The scanner handles permission itself, so a denial arrives as an error string.
            tvStatus.text = result.errorString
            tvStatus.visibility = View.VISIBLE
            resultPanel.visibility = View.GONE
            return
        }

        // A finished scan normally carries data, but guard it rather than assume.
        val data = result.data
        if (data == null) {
            tvStatus.setText(R.string.scan_no_data)
            tvStatus.visibility = View.VISIBLE
            resultPanel.visibility = View.GONE
            return
        }

        tvStatus.visibility = View.GONE
        resultPanel.visibility = View.VISIBLE

        // Validation is per field, so a joined full name is flagged when either half fails.
        val firstNameStatus = data.getFieldValidationStatus("firstName")
        val nameStatus = if (firstNameStatus == EnumValidationStatus.VS_FAILED) {
            firstNameStatus
        } else {
            data.getFieldValidationStatus("lastName")
        }
        val fullName = (data.firstName + " " + data.lastName).trim()

        applyField(findViewById(R.id.tv_full_name), fullName, nameStatus)
        applyField(findViewById(R.id.tv_doc_number), data.documentNumber,
            data.getFieldValidationStatus("documentNumber"))
        applyField(findViewById(R.id.tv_nationality), data.nationality,
            data.getFieldValidationStatus("nationality"))
        applyField(findViewById(R.id.tv_date_of_birth), data.dateOfBirth,
            data.getFieldValidationStatus("dateOfBirth"))
        applyField(findViewById(R.id.tv_date_of_expiry), data.dateOfExpire,
            data.getFieldValidationStatus("dateOfExpire"))
        // The document type comes from the MRZ layout itself, so it has no check digit.
        applyField(findViewById(R.id.tv_doc_type), data.documentType,
            EnumValidationStatus.VS_NONE)
        applyField(findViewById(R.id.tv_raw_mrz), data.mrzText,
            data.getFieldValidationStatus("mrzText"))

        showPortrait(result.portraitImage)
    }

    /** The portrait is returned by default, but is null when none could be cropped. */
    private fun showPortrait(portrait: ImageData?) {
        val ivPortrait = findViewById<ImageView>(R.id.iv_portrait)
        ivPortrait.visibility = View.GONE
        if (portrait == null) {
            return
        }
        try {
            ivPortrait.setImageBitmap(portrait.toBitmap())
            ivPortrait.visibility = View.VISIBLE
        } catch (ignored: CoreException) {
        }
    }

    /** Shows [value], or "N/A" when empty; amber when it fails its check digit. */
    private fun applyField(tv: TextView, value: String?, status: Int) {
        val failed = status == EnumValidationStatus.VS_FAILED
        tv.text = if (value.isNullOrEmpty()) "N/A" else value
        tv.setTextColor(
            ContextCompat.getColor(this, if (failed) R.color.warning_amber else R.color.white)
        )
    }
}
