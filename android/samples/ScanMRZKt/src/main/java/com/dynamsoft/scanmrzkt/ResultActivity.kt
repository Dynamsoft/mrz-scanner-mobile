package com.dynamsoft.scanmrzkt

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Bundle
import android.provider.Settings
import android.text.SpannableString
import android.text.Spanned
import android.text.style.ImageSpan
import android.text.style.UnderlineSpan
import android.view.View
import android.widget.ImageView
import android.widget.TextView

import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import androidx.fragment.app.Fragment
import androidx.viewpager2.adapter.FragmentStateAdapter
import androidx.viewpager2.widget.ViewPager2

import com.dynamsoft.core.basic_structures.CoreException
import com.dynamsoft.dcp.EnumValidationStatus
import com.dynamsoft.mrzscannerbundle.ui.EnumDocumentSide
import com.dynamsoft.mrzscannerbundle.ui.MRZScanResult
import com.google.android.material.tabs.TabLayout
import com.google.android.material.tabs.TabLayoutMediator

import java.util.Locale
import kotlin.math.roundToInt

class ResultActivity : AppCompatActivity() {

    /** True while this screen is showing a camera-permission denial rather than a result. */
    private var isShowingCameraPermissionError = false

    override fun onResume() {
        super.onResume()
        // They may have just granted access in Settings, so don't leave a stale denial up.
        if (isShowingCameraPermissionError && hasCameraPermission()) {
            setResult(RESULT_OK, intent.putExtra(EXTRA_ACTION, ACTION_RESCAN))
            finish()
        }
    }

    private fun hasCameraPermission(): Boolean =
        ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) ==
                PackageManager.PERMISSION_GRANTED

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_results)
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main)) { v, insets ->
            val systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars())
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom)
            insets
        }

        @Suppress("DEPRECATION")
        val scanResult = intent.getParcelableExtra<MRZScanResult>(EXTRA_RESULT)
        if (scanResult != null) {
            showMRZScanResult(scanResult)
        }

        findViewById<View>(R.id.btn_rescan).setOnClickListener {
            setResult(RESULT_OK, intent.putExtra(EXTRA_ACTION, ACTION_RESCAN))
            finish()
        }

        findViewById<View>(R.id.btn_return_home).setOnClickListener {
            setResult(RESULT_OK, intent.putExtra(EXTRA_ACTION, ACTION_RETURN_HOME))
            finish()
        }
    }

    private fun showMRZScanResult(result: MRZScanResult) {
        if (result.resultStatus == MRZScanResult.EnumResultStatus.RS_CANCELED) {
            // If the scan is canceled, we directly return to home without showing the result.
            setResult(RESULT_OK, intent.putExtra(EXTRA_ACTION, ACTION_RETURN_HOME))
            finish()
            return
        }
        if (result.resultStatus == MRZScanResult.EnumResultStatus.RS_EXCEPTION) {
            // If the scan is failed with error, we show the error message without showing the result.
            findViewById<View>(R.id.result_view).visibility = View.GONE
            val tvNoResult = findViewById<TextView>(R.id.no_result_view)
            tvNoResult.visibility = View.VISIBLE
            tvNoResult.text = result.errorString
            showCameraPermissionAction(result.errorCode)
            return
        }

        // A finished scan normally carries data, but guard it rather than assume.
        val data = result.data
        if (data == null) {
            findViewById<View>(R.id.result_view).visibility = View.GONE
            val tvNoData = findViewById<TextView>(R.id.no_result_view)
            tvNoData.visibility = View.VISIBLE
            tvNoData.setText(R.string.scan_no_data)
            return
        }

        findViewById<View>(R.id.result_view).visibility = View.VISIBLE
        findViewById<View>(R.id.no_result_view).visibility = View.GONE

        // Empty when unparsed; Locale.ROOT because this is an ICAO field, not localized text.
        val sexText = data.sex
        val genderText = if (sexText.isEmpty()) ""
        else sexText.substring(0, 1).uppercase(Locale.ROOT) + sexText.substring(1).lowercase(Locale.ROOT)

        // No highlighting: tinting "gender, age" on one field's status would implicate both.
        findViewById<TextView>(R.id.tv_full_name).text = (data.firstName + " " + data.lastName).trim()
        findViewById<TextView>(R.id.tv_gender_and_age).text =
            if (genderText.isEmpty() && data.age == 0) ""
            else "$genderText, ${data.age} years old"
        findViewById<TextView>(R.id.tv_expiry).text =
            if (data.dateOfExpire.isEmpty()) "" else "Expiry: ${data.dateOfExpire}"

        val ivPortrait = findViewById<ImageView>(R.id.iv_portrait)
        val portraitImage = result.portraitImage //Nullable
        if (portraitImage != null) {
            try {
                ivPortrait.setImageBitmap(portraitImage.toBitmap())
            } catch (ignored: CoreException) {
            }
        } else {
            ivPortrait.setImageResource(R.drawable.ic_portrait_placeholder)
        }

        //Images view pager
        showImages(result)

        //Personal Info
        applyField(findViewById(R.id.tv_given_name),    data.firstName,     data.getFieldValidationStatus("firstName"))
        applyField(findViewById(R.id.tv_surname),       data.lastName,      data.getFieldValidationStatus("lastName"))
        applyField(findViewById(R.id.tv_date_of_birth), data.dateOfBirth,   data.getFieldValidationStatus("dateOfBirth"))
        applyField(findViewById(R.id.tv_gender),        genderText,         data.getFieldValidationStatus("sex"))
        applyField(findViewById(R.id.tv_nationality),   data.nationality,   data.getFieldValidationStatus("nationality"))

        //Document Info
        val docTypeText = when (data.documentType ?: "") {
            "MRTD_TD1_ID" -> "ID (TD1)"
            "MRTD_TD2_ID" -> "ID (TD2)"
            "MRTD_TD3_PASSPORT" -> "Passport (TD3)"
            else -> ""
        }
        // documentType is derived from the MRZ code type, not an independently validated field.
        applyField(findViewById(R.id.tv_doc_type), docTypeText, EnumValidationStatus.VS_NONE)

        applyField(findViewById(R.id.tv_doc_number),  data.documentNumber, data.getFieldValidationStatus("documentNumber"))
        applyField(findViewById(R.id.tv_expiry_date), data.dateOfExpire,   data.getFieldValidationStatus("dateOfExpire"))

        // Tappable too: a line-composite failure can flag the MRZ when no single field did.
        applyField(findViewById(R.id.tv_raw_mrz), data.mrzText, data.getFieldValidationStatus("mrzText"))
    }

    /** Renders [value], or "N/A" when empty; a VS_FAILED value is amber and tappable. */
    private fun applyField(tv: TextView, value: String?, status: Int) {
        val failed = status == EnumValidationStatus.VS_FAILED

        val text = if (value.isNullOrEmpty()) "N/A" else value
        if (failed) {
            // Without the icon the value still underlines and turns amber.
            val icon = ContextCompat.getDrawable(this, R.drawable.ic_error_circle)
            val spannable = SpannableString(if (icon == null) text else "$text  ￼")
            if (icon != null) {
                val iconSize = (tv.textSize * 1.2f).roundToInt()
                icon.setBounds(0, 0, iconSize, iconSize)
                spannable.setSpan(
                    ImageSpan(icon, ImageSpan.ALIGN_BOTTOM),
                    spannable.length - 1, spannable.length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE
                )
            }
            spannable.setSpan(UnderlineSpan(), 0, text.length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
            tv.text = spannable
        } else {
            tv.text = text
        }
        tv.setTextColor(
            ContextCompat.getColor(this, if (failed) R.color.warning_amber else R.color.white)
        )

        if (failed) {
            tv.setOnClickListener { showValidationInfoDialog() }
        } else {
            tv.setOnClickListener(null)
            tv.isClickable = false
        }
    }

    /** Swaps Re-scan for Open Settings: re-scanning would only replay the declined dialog. */
    private fun showCameraPermissionAction(errorCode: Int) {
        // RESTRICTED means device policy withholds the camera; Settings has no toggle to offer.
        if (errorCode != MRZScanResult.EnumErrorCode.EC_CAMERA_PERMISSION_DENIED) {
            return
        }
        isShowingCameraPermissionError = true
        findViewById<View>(R.id.btn_rescan).visibility = View.GONE
        val btnOpenSettings = findViewById<View>(R.id.btn_open_settings)
        btnOpenSettings.visibility = View.VISIBLE
        btnOpenSettings.setOnClickListener {
            startActivity(
                Intent(
                    Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                    Uri.fromParts("package", packageName, null)
                )
            )
        }
    }

    private fun showValidationInfoDialog() {
        AlertDialog.Builder(this)
            .setTitle("Field validation warning")
            .setMessage("This value doesn't match its check digit. The document may be invalid or altered.")
            .setPositiveButton("OK", null)
            .show()
    }

    private fun showImages(result: MRZScanResult) {
        val mrzSideDocumentImage = result.getDocumentImage(EnumDocumentSide.DS_MRZ) //Nullable
        val oppositeSideDocumentImage = result.getDocumentImage(EnumDocumentSide.DS_OPPOSITE) //Nullable

        val mrzSideOriginalImage = result.getOriginalImage(EnumDocumentSide.DS_MRZ) //Nullable
        val oppositeSideOriginalImage = result.getOriginalImage(EnumDocumentSide.DS_OPPOSITE) //Nullable

        val tabImages = findViewById<TabLayout>(R.id.tab_images)
        val vpImages = findViewById<ViewPager2>(R.id.vp_images)
        val tvImagesHeader = findViewById<TextView>(R.id.tv_images_header)

        val hasProcessed = mrzSideDocumentImage != null || oppositeSideDocumentImage != null
        val hasOriginal = mrzSideOriginalImage != null || oppositeSideOriginalImage != null

        if (!hasProcessed && !hasOriginal) {
            tvImagesHeader.visibility = View.GONE
            tabImages.visibility = View.GONE
            vpImages.visibility = View.GONE
            return
        }

        // Tabs only when there are two sets to switch between; one set gets a plain header.
        val showsTabs = hasProcessed && hasOriginal
        tabImages.visibility = if (showsTabs) View.VISIBLE else View.GONE
        tvImagesHeader.visibility = if (showsTabs) View.GONE else View.VISIBLE
        tvImagesHeader.text = if (hasProcessed) "Processed Image(s)" else "Original Image(s)"
        vpImages.visibility = View.VISIBLE

        vpImages.adapter = object : FragmentStateAdapter(this) {
            override fun createFragment(position: Int): Fragment {
                // Page 0 is the processed pair when it exists, otherwise the original pair.
                return if (position == 0 && hasProcessed) {
                    ImagesFragment.newInstance(mrzSideDocumentImage, oppositeSideDocumentImage)
                } else {
                    ImagesFragment.newInstance(mrzSideOriginalImage, oppositeSideOriginalImage)
                }
            }

            override fun getItemCount(): Int {
                return if (hasProcessed && hasOriginal) 2 else 1
            }
        }

        if (showsTabs) {
            TabLayoutMediator(tabImages, vpImages) { tab, position ->
                tab.text = if (position == 0) "Processed" else "Original"
            }.attach()
        }
    }

    companion object {
        const val REQUEST_CODE = 1024

        const val EXTRA_RESULT = "RESULT"
        const val EXTRA_ACTION = "ACTION"
        const val ACTION_RESCAN = 0
        const val ACTION_RETURN_HOME = 1
    }
}
