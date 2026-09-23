package com.dynamsoft.mrzscannerbundle.ui;

import android.content.Context;
import android.graphics.Typeface;
import android.util.AttributeSet;
import android.view.LayoutInflater;
import android.view.animation.AccelerateDecelerateInterpolator;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.constraintlayout.widget.ConstraintLayout;

import com.dynamsoft.mrzscannerbundle.R;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

class BottomBarSelector extends ConstraintLayout {

    public static final String KEY_ID = "ID";
    public static final String KEY_BOTH = "BOTH";
    public static final String KEY_PASSPORT = "PASSPORT";

    public interface OnSelectedItemChangedListener {
        void onSelectedItemChanged(@NonNull String key);
    }

    private LinearLayout tabContainer;
    private TextView[] tabs;

    // Current display order: left, center(selected), right
    private final List<String> keys = new ArrayList<>(3);

    // key -> label shown on UI
    private final Map<String, String> labels = new HashMap<>(3);

    // The center item is always the selected item
    private static final int CENTER_INDEX = 1;

    private final List<OnSelectedItemChangedListener> listeners = new ArrayList<>();

    private boolean isAnimating = false;

    public BottomBarSelector(@NonNull Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
        LayoutInflater.from(context).inflate(R.layout.bottombar, this, true);

        tabContainer = findViewById(R.id.tabContainer);
        TextView tabId = findViewById(R.id.tab_id);
        TextView tabBoth = findViewById(R.id.tab_both);
        TextView tabPassport = findViewById(R.id.tab_passport);
        tabs = new TextView[]{tabId, tabBoth, tabPassport};

        // labels are used for UI display only; keys are internal identifiers
        labels.put(KEY_ID, labelOf(tabId, "ID"));
        labels.put(KEY_BOTH, labelOf(tabBoth, "Both"));
        labels.put(KEY_PASSPORT, labelOf(tabPassport, "Passport"));

        // Default display order: ID | BOTH(selected) | PASSPORT
        keys.clear();
        keys.addAll(Arrays.asList(KEY_ID, KEY_BOTH, KEY_PASSPORT));

        // Click: rotate by position so the clicked item becomes centered (selected)
        for (int i = 0; i < tabs.length; i++) {
            final int index = i;
            tabs[i].setOnClickListener(v -> {
                if (isAnimating) return;
                if (index == CENTER_INDEX) { // Already the center item
                    notifySelectedChanged();
                } else {
                    animateOneStep(index == 0 ? 1 : -1);
                }
            });
        }

        // Default: make center item selected
        post(() -> {
            syncTextsFromKeys();
            applySelectedStyle();
        });
    }

    private static String labelOf(TextView tab, String fallback) {
        return tab.getText() == null ? fallback : tab.getText().toString();
    }

    /// Select by stable key (KEY_ID/KEY_BOTH/KEY_PASSPORT); the selected item is always centered.
    public void selectItem(@NonNull String key) {
        if (isAnimating || tabs == null || tabs.length != 3 || keys.size() != 3) return;

        // Already selected: just update style/callback
        if (key.equals(keys.get(CENTER_INDEX))) {
            applySelectedStyle();
            notifySelectedChanged();
            return;
        }

        // Only one step rotation is needed
        int targetIndex = keys.indexOf(key);
        if (targetIndex != -1) {
            animateOneStep(targetIndex == 0 ? 1 : -1);
        }
    }

    @NonNull
    public String getSelectedKey() {
        if (keys.size() != 3) return "";
        String key = keys.get(CENTER_INDEX);
        return key == null ? "" : key;
    }

    public void addOnSelectedItemChangedListener(OnSelectedItemChangedListener listener) {
        if (listener != null && !listeners.contains(listener)) {
            listeners.add(listener);
        }
    }

    /// Slides one slot and re-centers; +1 rotates right ([0,1,2] -> [2,0,1]), -1 rotates left.
    private void animateOneStep(int direction) {
        isAnimating = true;
        tabContainer.animate()
                .translationX(direction * tabContainer.getWidth() / 3f)
                .setDuration(200)
                .setInterpolator(new AccelerateDecelerateInterpolator())
                .withEndAction(() -> {
                    Collections.rotate(keys, direction);
                    tabContainer.setTranslationX(0f);
                    syncTextsFromKeys();
                    applySelectedStyle();
                    notifySelectedChanged();
                    isAnimating = false;
                })
                .start();
    }

    private void syncTextsFromKeys() {
        for (int i = 0; i < 3; i++) {
            String key = keys.get(i);
            String label = labels.get(key);
            tabs[i].setText(label == null ? key : label);
        }
    }

    /// Restates every tab: labels rotate across fixed views, so a dimmed side tab must reset to 1f.
    private void applySelectedStyle() {
        for (int i = 0; i < 3; i++) {
            tabs[i].setTextColor(0xFFFFFFFF);
            tabs[i].setTypeface(null, i == CENTER_INDEX ? Typeface.BOLD : Typeface.NORMAL);
            tabs[i].setAlpha(i == CENTER_INDEX ? 1f : 0.8f);
        }
    }

    private void notifySelectedChanged() {
        final String selectedKey = getSelectedKey();
        for (OnSelectedItemChangedListener listener : listeners) {
            listener.onSelectedItemChanged(selectedKey);
        }
    }

    @Override
    public void setEnabled(boolean enabled) {
        super.setEnabled(enabled);
        for (int i = 0; i < 3; i++) {
            tabs[i].setEnabled(enabled);
            tabs[i].setClickable(enabled);
            if (i != CENTER_INDEX) {
                tabs[i].setAlpha(enabled ? 0.8f : 0.5f);
            }
        }
    }
}
