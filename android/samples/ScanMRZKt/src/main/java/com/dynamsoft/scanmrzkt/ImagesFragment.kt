package com.dynamsoft.scanmrzkt

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Bundle
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.LinearLayout

import androidx.fragment.app.Fragment

import com.dynamsoft.core.basic_structures.CoreException
import com.dynamsoft.core.basic_structures.ImageData

import java.io.ByteArrayOutputStream
import kotlin.math.max
import kotlin.math.roundToInt

// Images travel in setArguments — do NOT pass ImageData through a primary constructor.
class ImagesFragment : Fragment() {

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        val root = LinearLayout(requireContext())
        root.layoutParams = LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT
        )
        root.orientation = LinearLayout.HORIZONTAL
        root.gravity = Gravity.CENTER_VERTICAL
        root.isBaselineAligned = false
        root.clipToPadding = false
        root.clipChildren = false
        return root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        val args = arguments ?: return
        val root = view as LinearLayout
        val bytes1 = args.getByteArray(ARG_IMAGE_1)
        val bytes2 = args.getByteArray(ARG_IMAGE_2)

        addImageView(root, bytes1)
        if (bytes1 != null && bytes2 != null) {
            // 16dp spacer between the two images
            root.addView(
                View(requireContext()),
                LinearLayout.LayoutParams(
                    (16 * resources.displayMetrics.density).toInt(),
                    ViewGroup.LayoutParams.MATCH_PARENT
                )
            )
        }
        addImageView(root, bytes2)
    }

    private fun addImageView(root: LinearLayout, bytes: ByteArray?) {
        if (bytes == null) return
        val bmp = BitmapFactory.decodeByteArray(bytes, 0, bytes.size) ?: return
        val iv = ImageView(requireContext())
        iv.layoutParams = LinearLayout.LayoutParams(
            0, ViewGroup.LayoutParams.MATCH_PARENT, 1f
        )
        iv.scaleType = ImageView.ScaleType.FIT_CENTER
        iv.adjustViewBounds = true
        iv.setImageBitmap(bmp)
        root.addView(iv)
    }

    companion object {
        private const val ARG_IMAGE_1 = "image1"
        private const val ARG_IMAGE_2 = "image2"

        // Balances fidelity against the ~1 MB Binder cap on a saved-state Bundle.
        private const val JPEG_QUALITY = 85

        // Further hedge against that cap — 1024 px keeps each image under ~100 KB.
        private const val MAX_DIMENSION_PX = 1024

        fun newInstance(imageData1: ImageData?, imageData2: ImageData?): ImagesFragment {
            val fragment = ImagesFragment()
            val args = Bundle()
            encode(imageData1)?.let { args.putByteArray(ARG_IMAGE_1, it) }
            encode(imageData2)?.let { args.putByteArray(ARG_IMAGE_2, it) }
            fragment.arguments = args
            return fragment
        }

        private fun encode(imageData: ImageData?): ByteArray? {
            if (imageData == null) return null
            return try {
                val bmp = downscaleIfNeeded(imageData.toBitmap())
                val out = ByteArrayOutputStream()
                bmp.compress(Bitmap.CompressFormat.JPEG, JPEG_QUALITY, out)
                out.toByteArray()
            } catch (ignored: CoreException) {
                null
            }
        }

        private fun downscaleIfNeeded(src: Bitmap): Bitmap {
            val w = src.width
            val h = src.height
            val maxDimension = max(w, h)
            if (maxDimension <= MAX_DIMENSION_PX) return src
            val scale = MAX_DIMENSION_PX.toFloat() / maxDimension
            return Bitmap.createScaledBitmap(src, (w * scale).roundToInt(), (h * scale).roundToInt(), true)
        }
    }
}
