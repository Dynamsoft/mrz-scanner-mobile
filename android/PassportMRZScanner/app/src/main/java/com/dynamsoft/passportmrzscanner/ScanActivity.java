package com.dynamsoft.passportmrzscanner;

import android.app.AlertDialog;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.widget.ImageView;
import android.widget.TextView;

import com.dynamsoft.core.basic_structures.CapturedResultItem;
import com.dynamsoft.core.basic_structures.CompletionListener;
import com.dynamsoft.core.basic_structures.CoreModule;
import com.dynamsoft.core.basic_structures.EnumCapturedResultItemType;
import com.dynamsoft.core.basic_structures.EnumLogMode;
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
import com.dynamsoft.dcp.ParsedResult;
import com.dynamsoft.dcp.ParsedResultItem;
import com.dynamsoft.dlr.RecognizedTextLinesResult;
import com.dynamsoft.dlr.TextLineResultItem;
import com.dynamsoft.license.LicenseManager;
import com.dynamsoft.utility.MultiFrameResultCrossFilter;

import java.util.Calendar;
import java.util.HashMap;
import java.util.Locale;

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
	private AlertDialog mAlertDialog;
	private boolean succeed = false;
	private boolean mBeepStatus;
	private TextView mTextResult;
	private int mBirthYear;

	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_scan);
		PermissionUtil.requestCameraPermission(this);

		LicenseManager.initLicense("DLS2eyJvcmdhbml6YXRpb25JRCI6IjIwMDAwMSJ9",
				this,
				(isSuccess, error) -> {
					if (!isSuccess) {
						error.printStackTrace();
					}
				});
		mBeepStatusView = findViewById(R.id.iv_beep);
		mCameraView = findViewById(R.id.dce_camera_view);
		mTextResult = findViewById(R.id.tv_result);
		mCamera = new CameraEnhancer(mCameraView, this);

		try {
			mCamera.enableEnhancedFeatures(EnumEnhancerFeatures.EF_FRAME_FILTER);
		} catch (CameraEnhancerException e) {
			throw new RuntimeException(e);
		}
		toggleBeepButton();
		mRouter = new CaptureVisionRouter(this);
		MultiFrameResultCrossFilter filter = new MultiFrameResultCrossFilter();
		filter.enableResultCrossVerification(EnumCapturedResultItemType.CRIT_TEXT_LINE, true);
		mRouter.addResultFilter(filter);
		try {
			mRouter.initSettingsFromFile("PassportScanner.json");
			mRouter.setInput(mCamera);
		} catch (CaptureVisionRouterException e) {
			throw new RuntimeException(e);
		}

		mRouter.addResultReceiver(new CapturedResultReceiver() {
			@Override
			// Implement this method to receive RecognizedTextLinesResult.
			public void onRecognizedTextLinesReceived(@NonNull RecognizedTextLinesResult result) {
				onLabelTextReceived(result);
			}

			@Override
			public void onParsedResultsReceived(@NonNull ParsedResult result) {
				if (!succeed) {
					onParsedResultReceived(result);
				}
			}
		});
		mBeepStatusView.setOnClickListener((v)->{
			mBeepStatus = !mBeepStatus;
			updateBackground(mBeepStatus);
			saveBeepStatus();
		});
	}



	private void saveBeepStatus() {
		SharedPreferences sp = getSharedPreferences("beep", Context.MODE_PRIVATE);
		SharedPreferences.Editor editor=sp.edit();
		editor.putBoolean("status", mBeepStatus);
		editor.apply();
	}

	private boolean loadBeepStatus(){
		SharedPreferences sp = getSharedPreferences("beep", Context.MODE_PRIVATE);
		return  sp.getBoolean("status", true);
	}

	private void toggleBeepButton() {
		mBeepStatus = loadBeepStatus();
		updateBackground(mBeepStatus);
	}

	private void updateBackground(boolean status){
		if(status){
			mBeepStatusView.setBackground(ResourcesCompat.getDrawable(getResources(),
					R.drawable.icon_music, null));
		}else{
			mBeepStatusView.setBackground(ResourcesCompat.getDrawable(getResources(),
					R.drawable.icon_music_mute, null));
		}
	}

	@Override
	protected void onResume() {
		super.onResume();
		try {
			mCamera.open();
		} catch (CameraEnhancerException e) {
			e.printStackTrace();
		}
		mRouter.startCapturing("ReadPassport", new CompletionListener() {
			@Override
			public void onSuccess() {
			}

			@Override
			public void onFailure(int errorCode, String errorString) {
				runOnUiThread(() -> showDialog("Error", String.format(Locale.getDefault(),
						"ErrorCode: %d %nErrorMessage: %s", errorCode, errorString)));
			}
		});
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
		mCameraView.getDrawingLayer(DrawingLayer.DLR_LAYER_ID).clearDrawingItems();
		super.onStop();
	}

	private void onLabelTextReceived(RecognizedTextLinesResult result) {
		if (result.getItems() == null) {
			return;
		}
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
		if (result.getItems().length == 0) {
			runOnUiThread(() -> {
				if (!mText.isEmpty()) {
					String errorMsg = "error: Failed to parse the content. The MRZ text is " + mText;
					mTextResult.setText(errorMsg);
				}
			});
		} else {
			HashMap<String, String> labelMap = assembleMap(result.getItems()[0]);
			if (labelMap != null && !labelMap.isEmpty()) {
				if(mBeepStatus){
					Feedback.beep(this);
				}
				succeed = true;
				Intent intent = new Intent(this, ResultActivity.class);
				intent.putExtra("labelMap", labelMap);
				startActivity(intent);
				runOnUiThread(() -> {
					mTextResult.setText("");
				});

			} else {
				runOnUiThread(() -> {
					if (!mText.isEmpty()) {
						String errorMsg = "error: Failed to parse the content. The MRZ text is " + mText;
						mTextResult.setText(errorMsg);
					}
				});
			}

		}
	}

	private HashMap<String, String> assembleMap(ParsedResultItem item) {
		HashMap<String, String> entry = item.getParsedFields();
		String number = entry.get("passportNumber") == null ? entry.get("documentNumber") == null
				? "" : entry.get("documentNumber") : entry.get("passportNumber");
		String mName = entry.get("secondaryIdentifier") + " " + entry.get("primaryIdentifier");

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
		return properties;
	}

	private int calculateAge(int year, int month, int day) {
		Calendar calendar = Calendar.getInstance();
		int cYear = calendar.get(Calendar.YEAR);
		int cMonth = calendar.get(Calendar.MONTH);
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

	private void showDialog(String title, String message) {
		if (mAlertDialog == null) {
			mAlertDialog = new AlertDialog.Builder(this)
					.setCancelable(true)
					.setPositiveButton("OK", null)
					.create();
		}
		mAlertDialog.setTitle(title);
		mAlertDialog.setMessage(message);
		mAlertDialog.show();
	}
}
