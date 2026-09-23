package com.dynamsoft.mrzscannerbundle.ui;

import android.animation.ObjectAnimator;
import android.animation.ValueAnimator;
import android.graphics.drawable.Drawable;
import android.graphics.drawable.TransitionDrawable;
import android.os.Handler;
import android.os.Looper;
import android.provider.Settings;
import android.transition.AutoTransition;
import android.transition.ChangeBounds;
import android.transition.Transition;
import android.transition.TransitionManager;
import android.transition.TransitionSet;
import android.util.Log;
import android.util.SparseIntArray;
import android.view.View;
import android.view.ViewGroup;
import android.view.animation.LinearInterpolator;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.content.ContextCompat;

import com.dynamsoft.mrzscannerbundle.R;

final class CustomAnimator {

    private static final String TAG = "CustomAnimator";

    private static final long DEFAULT_ANIMATION_DURATION_MS = 300;
    private static final Handler MAIN = new Handler(Looper.getMainLooper());

    private static void runOnMainThread(@Nullable Runnable action) {
        if (action == null) return;
        if (Looper.myLooper() == Looper.getMainLooper()) {
            action.run();
        } else {
            MAIN.post(action);
        }
    }

    static void runOnMainThreadDelayed(long delayMs, @Nullable Runnable action) {
        if (action == null) return;
        MAIN.postDelayed(action, Math.max(0, delayMs));
    }

    /// Drops every pending post; MAIN is static, so posts outlive the activity that made them.
    static void cancelPendingPosts() {
        MAIN.removeCallbacksAndMessages(null);
    }

    private static final long FLIP_HALF_DURATION_MS = 750;
    private static final long FLIP_INITIAL_DELAY_MS = 200;
    private static final long FLIP_POST_LINGER_MS = 500;

    public static void startFlipAnimation(ImageView view) {
        if (view == null) return;
        runOnMainThread(() -> {
            stopFlipAnimation(view);
            view.setImageResource(R.drawable.ic_flip_original);
            view.setAlpha(1f);
            view.setRotationY(0f);
            view.setVisibility(View.VISIBLE);
            float density = view.getContext().getResources().getDisplayMetrics().density;
            view.setCameraDistance(8000 * density);

            final boolean[] stopped = {false};
            Runnable start = () -> {
                if (stopped[0]) return;
                view.animate()
                        .rotationY(90f)
                        .setDuration(FLIP_HALF_DURATION_MS)
                        .withEndAction(() -> {
                            if (stopped[0]) return;
                            view.setImageResource(R.drawable.ic_flip_after);
                            view.setRotationY(-90f);
                            view.animate()
                                    .rotationY(0f)
                                    .setDuration(FLIP_HALF_DURATION_MS)
                                    .withEndAction(() -> {
                                        if (stopped[0]) return;
                                        MAIN.postDelayed(() -> {
                                            if (!stopped[0]) stopFlipAnimation(view);
                                        }, FLIP_POST_LINGER_MS);
                                    })
                                    .start();
                        })
                        .start();
            };
            view.setTag(R.id.iv_flip_prompt, (Runnable) () -> {
                stopped[0] = true;
                view.animate().cancel();
            });
            MAIN.postDelayed(start, FLIP_INITIAL_DELAY_MS);
        });
    }

    public static void stopFlipAnimation(ImageView view) {
        if (view == null) return;
        runOnMainThread(() -> {
            Object tag = view.getTag(R.id.iv_flip_prompt);
            if (tag instanceof Runnable) {
                ((Runnable) tag).run();
                view.setTag(R.id.iv_flip_prompt, null);
            }
            view.animate().cancel();
            view.setAlpha(1f);
            view.setRotationY(0f);
            view.setVisibility(View.GONE);
        });
    }

    private static final long SPINNER_ROTATION_MS = 1000;

    public static void startScannerSpinner(ImageView view) {
        if (view == null) return;
        runOnMainThread(() -> {
            // Idempotent: if already spinning, just ensure visibility and return.
            Object existing = view.getTag(R.id.iv_scanner_spinner);
            if (existing instanceof ObjectAnimator && ((ObjectAnimator) existing).isRunning()) {
                if (view.getVisibility() != View.VISIBLE) view.setVisibility(View.VISIBLE);
                return;
            }

            view.setRotation(0f);
            view.setVisibility(View.VISIBLE);

            // Respect motion-reduction: if the system animator scale is 0, show a static spinner.
            float scale = Settings.Global.getFloat(
                    view.getContext().getContentResolver(),
                    Settings.Global.ANIMATOR_DURATION_SCALE, 1f);
            if (scale <= 0f) return;

            ObjectAnimator animator = ObjectAnimator.ofFloat(view, View.ROTATION, 0f, 360f);
            animator.setDuration(SPINNER_ROTATION_MS);
            animator.setInterpolator(new LinearInterpolator());
            animator.setRepeatCount(ValueAnimator.INFINITE);
            animator.setRepeatMode(ValueAnimator.RESTART);
            view.setTag(R.id.iv_scanner_spinner, animator);
            animator.start();
        });
    }

    public static void stopScannerSpinner(ImageView view) {
        if (view == null) return;
        runOnMainThread(() -> {
            Object tag = view.getTag(R.id.iv_scanner_spinner);
            // Idempotent: nothing to do if already stopped and hidden.
            if (tag == null && view.getVisibility() == View.GONE) return;

            if (tag instanceof ObjectAnimator) {
                ((ObjectAnimator) tag).cancel();
                view.setTag(R.id.iv_scanner_spinner, null);
            }
            view.setRotation(0f);
            view.setVisibility(View.GONE);
        });
    }

    public static void showNoPortraitTip(ViewGroup parent) {
        runOnMainThread(() -> {
            TransitionManager.beginDelayedTransition(parent, new TransitionSet()
                    .addTransition(new AutoTransition())
                    .setDuration(DEFAULT_ANIMATION_DURATION_MS));
            parent.findViewById(R.id.tv_no_portrait_tip).setVisibility(View.VISIBLE);
        });
    }

    /// Tip index -> string; TIP_CHAIN schedules the next index 1s later (4 -> 41 -> 42 -> 43).
    private static final SparseIntArray TIP_TEXTS = new SparseIntArray(10);
    private static final SparseIntArray TIP_CHAIN = new SparseIntArray(3);

    static {
        TIP_TEXTS.put(1, R.string.tip1);
        TIP_TEXTS.put(3, R.string.tip3);
        TIP_TEXTS.put(4, R.string.tip4);
        TIP_TEXTS.put(5, R.string.tip5);
        TIP_TEXTS.put(20, R.string.tip2);
        TIP_TEXTS.put(21, R.string.tip2_1);
        TIP_TEXTS.put(22, R.string.tip2_2);
        TIP_TEXTS.put(41, R.string.tip4_1);
        TIP_TEXTS.put(42, R.string.tip4_2);
        TIP_TEXTS.put(43, R.string.tip4_3);
        TIP_CHAIN.put(4, 41);
        TIP_CHAIN.put(41, 42);
        TIP_CHAIN.put(42, 43);
    }

    public static void showTip(ViewGroup parent, int tipIndex, long delayAfterAnimationEnd, AnimationListener listener) {
        // TransitionManager + View mutations must run on the main thread.
        runOnMainThread(() -> {
            TransitionManager.beginDelayedTransition(parent, new TransitionSet()
                    .addTransition(new ChangeBounds())
                    .addListener(new OnceTransitionListener(() -> {
                        if (listener == null) return;
                        runOnMainThreadDelayed(delayAfterAnimationEnd, listener::onAnimationEnd);
                    }))
                    .setDuration(DEFAULT_ANIMATION_DURATION_MS));

            TextView tip1 = parent.findViewById(R.id.tv_tip1);
            int text = TIP_TEXTS.get(tipIndex, 0);
            if (text == 0) {
                tip1.setVisibility(View.GONE);
                return;
            }
            tip1.setText(text);
            int nextIndex = TIP_CHAIN.get(tipIndex, 0);
            if (nextIndex != 0) {
                runOnMainThreadDelayed(1000, () -> showTip(parent, nextIndex, 0, null));
            }
        });
    }

    /// Dwell, not animation: the drawable swap is instant, so this is how long green shows first.
    private static final long GUIDE_GREEN_DWELL_MS = 600;
    /// Holds green *after* the tip appears; without it the border whitened in the same frame.
    private static final long GUIDE_GREEN_HOLD_AFTER_TIP_MS = 600;
    private static final long GUIDE_BORDER_FADE_MS = 300;

    public static void showGuideTextZoneAnimate(ViewGroup parent, boolean returnWhite, AnimationListener listener) {
        // All UI work must run on the main thread.
        runOnMainThread(() -> {
            View container = parent.findViewById(R.id.guide_frame_container);
            container.setBackground(ContextCompat.getDrawable(parent.getContext(), R.drawable.rounded_green_border));

            // Each run claims the border, so an older pending revert cannot whiten a newer green.
            final int generation = nextGuideBorderGeneration(container);

            runOnMainThreadDelayed(GUIDE_GREEN_DWELL_MS, () -> {
                // Caller first — it swaps the tip; green stays across that swap so both show together.
                if (listener != null) listener.onAnimationEnd();

                if (returnWhite) {
                    runOnMainThreadDelayed(GUIDE_GREEN_HOLD_AFTER_TIP_MS,
                            () -> fadeGuideBorderToWhite(container, generation));
                }

                View guideText = parent.findViewById(R.id.guide_frame_text);
                if (guideText.getVisibility() != View.VISIBLE) {
                    return;
                }
                TransitionManager.beginDelayedTransition(parent, new TransitionSet()
                        .addTransition(new AutoTransition())
                        .setDuration(DEFAULT_ANIMATION_DURATION_MS));
                guideText.setVisibility(View.GONE);
            });
        });
    }

    private static int nextGuideBorderGeneration(View container) {
        Object tag = container.getTag(R.id.guide_frame_container);
        int generation = (tag instanceof Integer ? (Integer) tag : 0) + 1;
        container.setTag(R.id.guide_frame_container, generation);
        return generation;
    }

    private static void fadeGuideBorderToWhite(View container, int generation) {
        Object tag = container.getTag(R.id.guide_frame_container);
        if (!(tag instanceof Integer) || (Integer) tag != generation) return;

        Drawable green = ContextCompat.getDrawable(container.getContext(), R.drawable.rounded_green_border);
        Drawable white = ContextCompat.getDrawable(container.getContext(), R.drawable.rounded_white_border);
        if (green == null || white == null) {
            container.setBackground(white);
            return;
        }

        // Cross-fade rather than swap, so the frame does not snap colour under the tip.
        TransitionDrawable fade = new TransitionDrawable(new Drawable[]{green, white});
        fade.setCrossFadeEnabled(true);
        container.setBackground(fade);
        fade.startTransition((int) GUIDE_BORDER_FADE_MS);
    }

    /// A tiny helper to avoid nested callbacks when several animations run in sequence.
    public static Sequencer sequence() {
        return new Sequencer();
    }

    public interface AnimationListener {
        void onAnimationEnd();
    }

    public interface Step {
        void run(@NonNull Runnable next);
    }

    public static final class Sequencer {
        private final java.util.ArrayDeque<Step> steps = new java.util.ArrayDeque<>();

        public Sequencer then(@NonNull Step step) {
            steps.add(step);
            return this;
        }

        public Sequencer then(@NonNull Runnable step) {
            steps.add(next -> {
                step.run();
                next.run();
            });
            return this;
        }

        public void start() {
            runOnMainThread(this::runNext);
        }

        private void runNext() {
            Step step = steps.poll();
            if (step == null) return;
            try {
                step.run(() -> runOnMainThread(this::runNext));
            } catch (Throwable t) {
                Log.e(TAG, "Sequencer step failed", t);
            }
        }
    }

    /// Fires once on end-or-cancel; implements the listener directly since the adapter is API 26.
    private static final class OnceTransitionListener implements Transition.TransitionListener {
        private final Runnable action;
        private boolean done = false;

        OnceTransitionListener(Runnable action) {
            this.action = action;
        }

        private void fireOnce() {
            if (done) return;
            done = true;
            action.run();
        }

        @Override public void onTransitionCancel(Transition t) { fireOnce(); }
        @Override public void onTransitionEnd(Transition t) { fireOnce(); }
        @Override public void onTransitionPause(Transition t) { }
        @Override public void onTransitionResume(Transition t) { }
        @Override public void onTransitionStart(Transition t) { }
    }
}
