package com.dynamsoft.scanmrz;

import android.os.Bundle;
import android.view.View;
import android.view.ViewGroup;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;

import com.dynamsoft.mrzscannerbundle.ui.MRZData;
import com.dynamsoft.mrzscannerbundle.ui.MRZScanResult;
import com.dynamsoft.mrzscannerbundle.ui.MRZScannerActivity;
import com.dynamsoft.mrzscannerbundle.ui.MRZScannerConfig;

import androidx.activity.result.ActivityResultLauncher;
import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.content.ContextCompat;

/**
 * @author dynamsoft
 */
public class MainActivity extends AppCompatActivity {
	private ActivityResultLauncher<MRZScannerConfig> launcher;
	private LinearLayout content;
	private TextView tvEmpty;

	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_main);
		content = findViewById(R.id.ll_content);
		tvEmpty = findViewById(R.id.tv_empty);

		//optional
		MRZScannerConfig config = new MRZScannerConfig();
		config.setLicense("DLS2eyJvcmdhbml6YXRpb25JRCI6IjIwMDAwMSJ9");
		config.setTorchButtonVisible(true);
		config.setCloseButtonVisible(true);
		//optional

		//must call
		launcher = registerForActivityResult(new MRZScannerActivity.ResultContract(), result -> {
			tvEmpty.setVisibility(View.GONE);
			if (result.getResultStatus() == MRZScanResult.EnumResultStatus.RS_FINISHED) {
				if (result.getData() != null) {
					MRZData data = result.getData();
					content.removeAllViews();
					content.addView(childView("Name:", data.getFirstName() + " " + data.getLastName()));
					content.addView(childView("Sex:", data.getSex() == null ? ""
							: data.getSex().substring(0, 1).toUpperCase() + data.getSex().substring(1)));
					content.addView(childView("Age:", data.getAge() + ""));
					content.addView(childView("Document Type:", data.getDocumentType()));
					content.addView(childView("Document Number:", data.getDocumentNumber()));
					content.addView(childView("Issuing State:", data.getIssuingState()));
					content.addView(childView("Nationality:", data.getNationality()));
					content.addView(childView("Date of Birth(YYYY-MM-DD):", data.getDateOfBirth()));
					content.addView(childView("Date of Expiry(YYYY-MM-DD):", data.getDateOfExpire()));
				}
			} else if (result.getResultStatus() == MRZScanResult.EnumResultStatus.RS_CANCELED) {
				content.removeAllViews();
				content.addView(childView("Scan canceled.", ""));
			}
			if (result.getErrorString() != null && !result.getErrorString().isEmpty()) {
				content.removeAllViews();
				content.addView(childView("Error:", result.getErrorString()));
			}
		});

		findViewById(R.id.btn_nav).setOnClickListener(v -> {
			launcher.launch(config);
		});

	}

	@NonNull
	private View childView(String label, String labelText) {
		LinearLayout layout = new LinearLayout(this);
		LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT,
				ViewGroup.LayoutParams.WRAP_CONTENT);
		params.setMargins(0, 30, 0, 0);
		layout.setLayoutParams(params);
		layout.setOrientation(LinearLayout.VERTICAL);
		TextView labelView = new TextView(this);
		labelView.setPadding(0, 30, 0, 0);
		labelView.setTextColor(ContextCompat.getColor(this, R.color.dy_grey_AA));
		labelView.setTextSize(16);
		labelView.setText(label);
		TextView textView = new TextView(this);
		textView.setTextSize(16);
		textView.setText(labelText);
		layout.addView(labelView);
		layout.addView(textView);
		return layout;
	}
}