package com.dynamsoft.mrzscanner;

import android.content.Context;
import android.util.AttributeSet;
import android.view.View;
import android.widget.LinearLayout;
import android.widget.TextView;

/**
 * @author: dynamsoft
 * Time: 2024/8/23
 * Description:
 */
public class TabSelector extends LinearLayout {
	private OnTabSelectListener mListener;

	public TabSelector(Context context) {
		super(context);
		initView();
	}

	public TabSelector(Context context, AttributeSet attrs) {
		super(context, attrs);
		initView();
	}

	private void initView() {
		View rootView = inflate(getContext(), R.layout.tab_selector, this);
		TextView tvId = rootView.findViewById(R.id.tv_id);
		TextView tvPassport = rootView.findViewById(R.id.tv_passport);
		TextView tvBoth = rootView.findViewById(R.id.tv_both);
		tvId.setOnClickListener(new SelectorClickListener());
		tvPassport.setOnClickListener(new SelectorClickListener());
		tvBoth.setOnClickListener(new SelectorClickListener());
		tvBoth.setSelected(true);
	}

	public void setOnTabSelectListener(OnTabSelectListener listener) {
		mListener = listener;
	}

	public interface OnTabSelectListener {
		void onTabSelected(int tab, View v);
	}

	class SelectorClickListener implements OnClickListener {
		@Override
		public void onClick(View v) {
			if (v.getId() == R.id.tv_id) {
				v.setSelected(true);
				findViewById(R.id.tv_passport).setSelected(false);
				findViewById(R.id.tv_both).setSelected(false);
				if (mListener != null) {
					mListener.onTabSelected(0, v);
				}
			} else if (v.getId() == R.id.tv_passport) {
				v.setSelected(true);
				findViewById(R.id.tv_id).setSelected(false);
				findViewById(R.id.tv_both).setSelected(false);
				if (mListener != null) {
					mListener.onTabSelected(1, v);
				}
			} else if (v.getId() == R.id.tv_both) {
				v.setSelected(true);
				findViewById(R.id.tv_id).setSelected(false);
				findViewById(R.id.tv_passport).setSelected(false);
				if (mListener != null) {
					mListener.onTabSelected(2, v);
				}
			}
		}
	}
}
