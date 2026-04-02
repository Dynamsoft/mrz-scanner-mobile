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

    public BottomBarSelector(@NonNull Context context) {
        super(context);
        init(context);
    }

    public BottomBarSelector(@NonNull Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
        init(context);
    }

    public BottomBarSelector(@NonNull Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        init(context);
    }

    private void init(Context context) {
        LayoutInflater.from(context).inflate(R.layout.bottombar, this, true);

        tabContainer = findViewById(R.id.tabContainer);

        TextView tabId = findViewById(R.id.tab_id);
        TextView tabBoth = findViewById(R.id.tab_both);
        TextView tabPassport = findViewById(R.id.tab_passport);
        tabs = new TextView[]{tabId, tabBoth, tabPassport};

        // labels are used for UI display only; keys are internal identifiers
        labels.put(KEY_ID, tabId.getText() == null ? "ID" : tabId.getText().toString());
        labels.put(KEY_BOTH, tabBoth.getText() == null ? "Both" : tabBoth.getText().toString());
        labels.put(KEY_PASSPORT, tabPassport.getText() == null ? "Passport" : tabPassport.getText().toString());

        // Default display order: ID | BOTH(selected) | PASSPORT
        keys.clear();
        keys.add(KEY_ID);
        keys.add(KEY_BOTH);
        keys.add(KEY_PASSPORT);

        // Click: rotate by position so the clicked item becomes centered (selected)
        for (int i = 0; i < tabs.length; i++) {
            final int index = i;
            tabs[i].setOnClickListener(v -> {
                if (isAnimating) return;

                // Already the center item
                if (index == CENTER_INDEX) {
                    notifySelectedChanged();
                    return;
                }

                if (index == 0) {
                    // left -> center: rotate right
                    animateOneStepRight();
                } else if (index == 2) {
                    // right -> center: rotate left
                    animateOneStepLeft();
                }
            });
        }

        // Default: make center item selected
        post(() -> {
            syncTextsFromKeys();
            applySelectedStyle();
        });
    }

    /**
     * Select an item by stable key (KEY_ID/KEY_BOTH/KEY_PASSPORT). The selected item is always centered.
     */
    public void selectItem(@NonNull String key) {
        if (isAnimating) return;
        if (tabs == null || tabs.length != 3) return;
        if (keys.size() != 3) return;

        // Already selected: just update style/callback
        if (key.equals(keys.get(CENTER_INDEX))) {
            applySelectedStyle();
            notifySelectedChanged();
            return;
        }

        int targetIndex = keys.indexOf(key);
        if (targetIndex == -1) return;

        // Only one step rotation is needed
        if (targetIndex == 2) {
            animateOneStepLeft();
        } else if (targetIndex == 0) {
            animateOneStepRight();
        }
    }

    @NonNull
    public String getSelectedKey() {
        if (keys.size() != 3) return "";
        String k = keys.get(CENTER_INDEX);
        return k == null ? "" : k;
    }

    public void addOnSelectedItemChangedListener(OnSelectedItemChangedListener listener) {
        if (listener != null && !listeners.contains(listener)) {
            listeners.add(listener);
        }
    }

    public void removeOnSelectedItemChangedListener(OnSelectedItemChangedListener listener) {
        listeners.remove(listener);
    }

    private void animateOneStepLeft() {
        isAnimating = true;

        final float step = tabContainer.getWidth() / 3f;

        tabContainer.animate()
                .translationX(-step)
                .setDuration(200)
                .setInterpolator(new AccelerateDecelerateInterpolator())
                .withEndAction(() -> {
                    rotateLeftKeys();
                    tabContainer.setTranslationX(0f);
                    syncTextsFromKeys();
                    applySelectedStyle();
                    notifySelectedChanged();
                    isAnimating = false;
                })
                .start();
    }

    private void animateOneStepRight() {
        isAnimating = true;

        final float step = tabContainer.getWidth() / 3f;

        tabContainer.animate()
                .translationX(step)
                .setDuration(200)
                .setInterpolator(new AccelerateDecelerateInterpolator())
                .withEndAction(() -> {
                    rotateRightKeys();
                    tabContainer.setTranslationX(0f);
                    syncTextsFromKeys();
                    applySelectedStyle();
                    notifySelectedChanged();
                    isAnimating = false;
                })
                .start();
    }

    private void rotateLeftKeys() {
        // [0,1,2] -> [1,2,0]
        String first = keys.get(0);
        keys.set(0, keys.get(1));
        keys.set(1, keys.get(2));
        keys.set(2, first);
    }

    private void rotateRightKeys() {
        // [0,1,2] -> [2,0,1]
        String last = keys.get(2);
        keys.set(2, keys.get(1));
        keys.set(1, keys.get(0));
        keys.set(0, last);
    }

    private void syncTextsFromKeys() {
        for (int i = 0; i < 3; i++) {
            String key = keys.get(i);
            String label = labels.get(key);
            tabs[i].setText(label == null ? key : label);
        }
    }

    private void applySelectedStyle() {
        for (int i = 0; i < 3; i++) {
            if (i == CENTER_INDEX) {
                tabs[i].setTextColor(0xFFFFFFFF);
                tabs[i].setTypeface(null, Typeface.BOLD);
            } else {
                tabs[i].setTextColor(0xFFFFFFFF);
                tabs[i].setAlpha(0.8f);
                tabs[i].setTypeface(null, Typeface.NORMAL);
            }
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