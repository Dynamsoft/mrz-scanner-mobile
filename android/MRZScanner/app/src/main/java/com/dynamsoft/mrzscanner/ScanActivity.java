package com.dynamsoft.mrzscanner;

import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.graphics.Color;
import android.os.Bundle;
import android.text.SpannableString;
import android.text.Spanned;
import android.text.style.ForegroundColorSpan;
import android.view.View;
import android.widget.ImageView;
import android.widget.TextView;

import com.dynamsoft.core.basic_structures.CompletionListener;
import com.dynamsoft.core.basic_structures.EnumCapturedResultItemType;
import com.dynamsoft.cvr.CaptureVisionRouter;
import com.dynamsoft.cvr.CaptureVisionRouterException;
import com.dynamsoft.cvr.CapturedResultReceiver;
import com.dynamsoft.dce.CameraEnhancer;
import com.dynamsoft.dce.CameraEnhancerException;
import com.dynamsoft.dce.CameraView;
import com.dynamsoft.dce.DrawingLayer;
import com.dynamsoft.dce.EnumEnhancerFeatures;
import com.dynamsoft.dce.Feedback;
import com.dynamsoft.dce.utils.PermissionUtil;
import com.dynamsoft.dcp.EnumValidationStatus;
import com.dynamsoft.dcp.ParsedResult;
import com.dynamsoft.dcp.ParsedResultItem;
import com.dynamsoft.dlr.RecognizedTextLinesResult;
import com.dynamsoft.dlr.TextLineResultItem;
import com.dynamsoft.license.LicenseManager;
import com.dynamsoft.utility.MultiFrameResultCrossFilter;

import java.util.Calendar;
import java.util.HashMap;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.content.res.ResourcesCompat;

/**
 * @author: dynamsoft
 * Time: 2024/6/13
 * Description:
 */
public class ScanActivity extends AppCompatActivity {
	private CameraEnhancer mCamera;
	private CameraView mCameraView;
	private ImageView mBeepStatusView;
	private CaptureVisionRouter mRouter;
	private String mText;
	private boolean succeed = false;
	private boolean mBeepStatus;
	private TextView mTextResult;
	private TextView mInitError;
	private TextView mStartError;
	private TextView mAlert;
	private int mBirthYear;
	private String mCurrentTemplate;

	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_scan);
		PermissionUtil.requestCameraPermission(this);
		// Initialize the license.
		// The license string here is a trial license. Note that network connection is required for this license to work.
		// You can request an extension via the following link: https://www.dynamsoft.com/customer/license/trialLicense?product=mrz&utm_source=samples&package=android
		LicenseManager.initLicense("DLS2eyJvcmdhbml6YXRpb25JRCI6IjIwMDAwMSJ9",
				this,
				(isSuccess, error) -> {
					if (!isSuccess) {
						runOnUiThread(() -> {
							mInitError.setVisibility(View.VISIBLE);
							mInitError.setText("License initialization failed: " + error.getMessage());
						});
						error.printStackTrace();
					}
				});
		mBeepStatusView = findViewById(R.id.iv_beep);
		mCameraView = findViewById(R.id.dce_camera_view);
		mTextResult = findViewById(R.id.tv_result);
		mInitError = findViewById(R.id.tv_init_license_error);
		mStartError = findViewById(R.id.tv_start_license_error);
		mAlert = findViewById(R.id.tv_alert);
		TabSelector mTabSelector = findViewById(R.id.tab_selector);
		
		// CameraEnhancer is the class for controlling the camera and obtaining high-quality video input.
		mCamera = new CameraEnhancer(mCameraView, this);

		// Enable the frame filter feature. It will improve the accuracy of the MRZ scanning.
		try {
			mCamera.enableEnhancedFeatures(EnumEnhancerFeatures.EF_FRAME_FILTER);
		} catch (CameraEnhancerException e) {
			throw new RuntimeException(e);
		}
		toggleBeepButton();

		// CaptureVisionRouter is the class for you to configure settings, retrieve images, start MRZ scanning and receive results.
		mRouter = new CaptureVisionRouter(this);

		// Enable the multi-frame cross verification feature. It will improve the accuracy of the MRZ scanning.
		MultiFrameResultCrossFilter filter = new MultiFrameResultCrossFilter();
		filter.enableResultCrossVerification(EnumCapturedResultItemType.CRIT_TEXT_LINE, true);
		mRouter.addResultFilter(filter);

		try {
			// Set the input.
			mRouter.setInput(mCamera);
		} catch (CaptureVisionRouterException e) {
			throw new RuntimeException(e);
		}

		mCurrentTemplate = "ReadPassportAndId";
		mRouter.addResultReceiver(new CapturedResultReceiver() {

			// Implement this method to receive raw MRZ recognized results. It includes the string only.
			@Override
			public void onRecognizedTextLinesReceived(@NonNull RecognizedTextLinesResult result) {
				onLabelTextReceived(result);
			}

			// Implement this method to receive parsed MRZ results. It includes the detailed information.
			@Override
			public void onParsedResultsReceived(@NonNull ParsedResult result) {
				if (!succeed) {
					onParsedResultReceived(result);
				}
			}
		});
		mBeepStatusView.setOnClickListener((v) -> {
			mBeepStatus = !mBeepStatus;
			updateBackground(mBeepStatus);
			saveBeepStatus();
		});

		// This is the UI component to switch between different templates.
		mTabSelector.setOnTabSelectListener((tab, v) -> {
			switch (tab) {
				case 0:
					if (!"ReadId".equals(mCurrentTemplate)) {
						mCurrentTemplate = "ReadId";
						// To swith the template, you need to stop the capturing first.
						mRouter.stopCapturing();
						// Restart the capturing with the new template. This method is implemented below.
						restartCapture(mCurrentTemplate);
					}
					break;
				case 1:
					if (!"ReadPassport".equals(mCurrentTemplate)) {
						mCurrentTemplate = "ReadPassport";
						mRouter.stopCapturing();
						restartCapture(mCurrentTemplate);
					}
					break;
				case 2:
					if (!"ReadPassportAndId".equals(mCurrentTemplate)) {
						mCurrentTemplate = "ReadPassportAndId";
						mRouter.stopCapturing();
						restartCapture(mCurrentTemplate);
					}
					break;
				default:
			}
		});
	}


	private void saveBeepStatus() {
		SharedPreferences sp = getSharedPreferences("beep", Context.MODE_PRIVATE);
		SharedPreferences.Editor editor = sp.edit();
		editor.putBoolean("status", mBeepStatus);
		editor.apply();
	}

	private boolean loadBeepStatus() {
		SharedPreferences sp = getSharedPreferences("beep", Context.MODE_PRIVATE);
		return sp.getBoolean("status", true);
	}

	private void toggleBeepButton() {
		mBeepStatus = loadBeepStatus();
		updateBackground(mBeepStatus);
	}

	private void updateBackground(boolean status) {
		if (status) {
			mBeepStatusView.setBackground(ResourcesCompat.getDrawable(getResources(),
					R.drawable.icon_music, null));
		} else {
			mBeepStatusView.setBackground(ResourcesCompat.getDrawable(getResources(),
					R.drawable.icon_music_mute, null));
		}
	}

	// The implementation of restartCapture(). 
	private void restartCapture(String template) {
		// Start capturing.
		// The template name is a string specified in the template file. 
		// In this sample we can use "ReadPassportAndId", "ReadId" and "ReadPassport".
		// Here the template name is what the user selected on the UI.
		// The completion listener is implemented below. It calls back when the capturing is successful or failed.
		mRouter.startCapturing(template, new CompletionListener() {
			@Override
			public void onSuccess() {
			}

			// If failed, it shows an error message that describes the reasons.
			// License error can be one of the reason of a failure. Besure that you have a valid license when starting capturing.
			@Override
			public void onFailure(int errorCode, String errorString) {
				runOnUiThread(() -> {
					mStartError.setVisibility(View.VISIBLE);
					mStartError.setText(errorString);
				});
			}
		});
	}

	@Override
	protected void onResume() {
		super.onResume();
		try {
			mCamera.open();
		} catch (CameraEnhancerException e) {
			e.printStackTrace();
		}
		restartCapture(mCurrentTemplate);
	}

	@Override
	protected void onPause() {
		super.onPause();
		succeed = false;
		try {
			mCamera.close();

		} catch (CameraEnhancerException e) {
			e.printStackTrace();
		}
		mRouter.stopCapturing();
	}

	@Override
	protected void onStop() {
		// DrawingItem in this sample is the green quadrilateral that highlights the recognized text.
		// Clear the DrawingItem before you leave the camera page. 
		mCameraView.getDrawingLayer(DrawingLayer.DLR_LAYER_ID).clearDrawingItems();
		super.onStop();
	}

	private void onLabelTextReceived(RecognizedTextLinesResult result) {
		// The following code shows how to obtain the recognized MRZ text.
		if (result.getItems() == null) {
			return;
		}
		// RecognizedTextLinesResult contains an array of TextLineResultItem. Each TextLineResultItem contains a single recognized text.
		TextLineResultItem[] results = result.getItems();
		StringBuilder resultBuilder = new StringBuilder();
		if (results != null) {
			for (TextLineResultItem item : results) {
				resultBuilder.append(item.getText()).append("\n\n");
			}
		}
		mText = resultBuilder.toString();
	}

	private void onParsedResultReceived(ParsedResult result) {
		if (result.getItems() == null) {
			return;
		}
		// If failed to parse the MRZ, the following code shows the recognized text on the view.
		if (result.getItems().length == 0) {
			runOnUiThread(() -> {
				if (!mText.isEmpty()) {
					combineErrorTexts(mText);
				}
			});
		} else {
			// ParsedResult contains all parsed results that are captured from an image.
			// From a ParsedResult object, you can get an array of ParsedResultItems.
			// Each ParsedResultItem comes from a single MRZ text.
			// Method assembleMap() is implemented below. It extracts parsed info from the ParsedResultItem.
			HashMap<String, String> labelMap = assembleMap(result.getItems()[0]);
			// Go to the result page if the labelMap is not empty.
			if (labelMap != null && !labelMap.isEmpty()) {
				// Trigger a beep sound if required.
				if (mBeepStatus) {
					Feedback.beep(this);
				}
				succeed = true;
				Intent intent = new Intent(this, ResultActivity.class);
				intent.putExtra("labelMap", labelMap);
				startActivity(intent);
				runOnUiThread(this::clearText);

			} else {
				// Shows the recognized text if the labelMap is empty.
				runOnUiThread(() -> {
					if (!mText.isEmpty()) {
						combineErrorTexts(mText);
					}
				});
			}

		}
	}

	private void combineErrorTexts(String error) {
		mAlert.setText("Error: Failed to parse the content.");
		mTextResult.setText("The MRZ text is: \n" + error);
	}

	private void clearText(){
		mAlert.setText("");
		mTextResult.setText("");
	}


	// Assemble the parsed info from the ParsedResultItem.
	private HashMap<String, String> assembleMap(ParsedResultItem item) {
		// Parsed fields are stored in a HashMap with field name as the key and field value as the value.
		// The following code shows how to get the parsed field values.
		HashMap<String, String> entry = item.getParsedFields();
		String mDocumentType = "";
		if (item.getCodeType().equals("MRTD_TD1_ID") || item.getCodeType().equals("MRTD_TD2_ID") || item.getCodeType().equals("MRTD_TD2_FRENCH_ID")) {
			mDocumentType = "ID";
		} else if (item.getCodeType().equals("MRTD_TD3_PASSPORT")) {
			mDocumentType = "PASSPORT";
		}

		String number = entry.get("passportNumber") == null ? entry.get("documentNumber") == null
				? "" : entry.get("documentNumber") : entry.get("passportNumber");
		String mFirstName = entry.get("secondaryIdentifier") == null ? "" : entry.get("secondaryIdentifier");
		String mLastName = entry.get("primaryIdentifier") == null ? "" : " " + entry.get("primaryIdentifier");
		String mName = mFirstName + mLastName;
		if (number == null ||
				entry.get("sex") == null ||
				entry.get("issuingState") == null ||
				entry.get("nationality") == null ||
				entry.get("secondaryIdentifier") == null ||
				entry.get("primaryIdentifier") == null ||
				entry.get("dateOfBirth") == null ||
				entry.get("dateOfExpiry") == null) {
			return null;
		}

		if (item.getCodeType().equals("MRTD_TD1_ID")) {
			if (item.getFieldValidationStatus("line1") == EnumValidationStatus.VS_FAILED
					|| item.getFieldValidationStatus("line2") == EnumValidationStatus.VS_FAILED
					|| item.getFieldValidationStatus("line3") == EnumValidationStatus.VS_FAILED) {
				return null;
			}
		} else {
			if (item.getFieldValidationStatus("line1") == EnumValidationStatus.VS_FAILED
					|| item.getFieldValidationStatus("line2") == EnumValidationStatus.VS_FAILED) {
				return null;
			}
		}

		int age = -1;
		int expiryYear = 0;
		try {
			int year = Integer.parseInt(entry.get("birthYear"));
			int month = Integer.parseInt(entry.get("birthMonth"));
			int day = Integer.parseInt(entry.get("birthDay"));
			expiryYear = Integer.parseInt(entry.get("expiryYear")) + 2000;
			age = calculateAge(year, month, day);
		} catch (Exception e) {
			e.printStackTrace();
		}
		HashMap<String, String> properties = new HashMap<>(11);
		properties.put("Name", mName);
		properties.put("Sex", entry.get("sex"));
		properties.put("Age", age == -1 ? "Unknown" : age + "");
		properties.put("Document Number", number);
		properties.put("Issuing State", entry.get("issuingState"));
		properties.put("Nationality", entry.get("nationality"));
		properties.put("Date of Birth(YY-MM-DD)", mBirthYear + "-" +
				entry.get("birthMonth") + "-" + entry.get("birthDay"));
		properties.put("Date of Expiry(YY-MM-DD)", expiryYear + "-" +
				entry.get("expiryMonth") + "-" + entry.get("expiryDay"));
		properties.put("Personal Number", entry.get("personalNumber"));
		properties.put("Primary Identifier(s)", entry.get("primaryIdentifier"));
		properties.put("Secondary Identifier(s)", entry.get("secondaryIdentifier"));
		properties.put("Document Type", mDocumentType);
		return properties;
	}

    // Age information is not directly obtained from the MRZ but you can calculate it based on the date of birth.
	// The following 2 methods are used to calculate the age.
	private int calculateAge(int year, int month, int day) {
		Calendar calendar = Calendar.getInstance();
		int cYear = calendar.get(Calendar.YEAR);
		int cMonth = calendar.get(Calendar.MONTH) + 1;
		int cDay = calendar.get(Calendar.DAY_OF_MONTH);
		mBirthYear = 1900 + year;
		int diffYear = cYear - mBirthYear;
		int diffMonth = cMonth - month;
		int diffDay = cDay - day;
		int age = minusYear(diffYear, diffMonth, diffDay);
		if (age > 100) {
			mBirthYear = 2000 + year;
			diffYear = cYear - mBirthYear;
			age = minusYear(diffYear, diffMonth, diffDay);
		} else if (age < 0) {
			age = 0;
		}
		return age;
	}

	private int minusYear(int diffYear, int diffMonth, int diffDay) {
		int age = Math.max(diffYear, 0);
		if (diffMonth < 0) {
			age = age - 1;

		} else if (diffMonth == 0) {
			if (diffDay < 0) {
				age = age - 1;
			}
		}
		return age;
	}
}
