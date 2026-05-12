package com.dynamsoft.mrzscannerbundle.ui;

import android.os.Handler;
import android.os.Looper;
import android.transition.AutoTransition;
import android.transition.ChangeBounds;
import android.transition.Transition;
import android.transition.TransitionManager;
import android.transition.TransitionSet;
import android.util.Log;
import android.view.View;
import android.view.ViewGroup;
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

    public static void showNoPortraitTip(ViewGroup parent) {
        runOnMainThread(() -> {
            TransitionSet set = new TransitionSet()
                    .addTransition(new AutoTransition())
                    .setDuration(DEFAULT_ANIMATION_DURATION_MS);
            TransitionManager.beginDelayedTransition(parent, set);
            TextView tip = parent.findViewById(R.id.tv_no_portrait_tip);
            tip.setVisibility(View.VISIBLE);
        });
    }

    public static void showTip(ViewGroup parent, int tipIndex, long delayAfterAnimationEnd, AnimationListener listener) {
        // TransitionManager + View mutations must run on the main thread.
        runOnMainThread(() -> {
            TransitionSet set = new TransitionSet()
                    .addTransition(new ChangeBounds())
                    .addListener(new SimpleTransitionListener() {
                        @Override
                        void onAnimationEnd() {
                            if (listener == null) return;
                            runOnMainThreadDelayed(delayAfterAnimationEnd, listener::onAnimationEnd);
                        }
                    })
                    .setDuration(DEFAULT_ANIMATION_DURATION_MS);
            TransitionManager.beginDelayedTransition(parent, set);

            TextView tip1 = parent.findViewById(R.id.tv_tip1);
            switch (tipIndex) {
                case 1:
                    tip1.setText(R.string.tip1);
                    break;
                case 20:
                    tip1.setText(R.string.tip2);
                    break;
                case 21:
                    tip1.setText(R.string.tip2_1);
                    break;
                case 22:
                    tip1.setText(R.string.tip2_2);
                    break;
                case 3:
                    tip1.setText(R.string.tip3);
                    break;
                case 4:
                    tip1.setText(R.string.tip4);
                    runOnMainThreadDelayed(1000, () -> showTip(parent, 41, 0, null));
                    break;
                case 41:
                    tip1.setText(R.string.tip4_1);
                    runOnMainThreadDelayed(1000, () -> showTip(parent, 42, 0, null));
                    break;
                case 42:
                    tip1.setText(R.string.tip4_2);
                    runOnMainThreadDelayed(1000, () -> showTip(parent, 43, 0, null));
                    break;
                case 43:
                    tip1.setText(R.string.tip4_3);
                    break;
                case 5:
                    tip1.setText(R.string.tip5);
                    break;
                default:
                    tip1.setVisibility(View.GONE);
            }
        });
    }

    public static void showGuideTextZoneAnimate(ViewGroup parent, boolean returnWhite, AnimationListener listener) {
        // All UI work must run on the main thread.
        runOnMainThread(() -> {
            parent.findViewById(R.id.guide_frame_container)
                    .setBackground(ContextCompat.getDrawable(parent.getContext(), R.drawable.rounded_green_border));

            runOnMainThreadDelayed(600, () -> {
                if (listener != null) listener.onAnimationEnd();
                View guideText = parent.findViewById(R.id.guide_frame_text);
                if (returnWhite) {
                    parent.findViewById(R.id.guide_frame_container)
                            .setBackground(ContextCompat.getDrawable(parent.getContext(), R.drawable.rounded_white_border));
                }
                if (guideText.getVisibility() != View.VISIBLE) {
//                    if (returnWhite) {
//                        parent.findViewById(R.id.guide_frame_container)
//                                .setBackground(ContextCompat.getDrawable(parent.getContext(), R.drawable.rounded_white_border));
//                    }
                    return;
                }

                TransitionSet visibilitySet = new TransitionSet()
                        .addTransition(new AutoTransition())
                        .addListener(new SimpleTransitionListener() {
                            @Override
                            void onAnimationEnd() {
//                                if (returnWhite) {
//                                    parent.findViewById(R.id.guide_frame_container)
//                                            .setBackground(ContextCompat.getDrawable(parent.getContext(), R.drawable.rounded_white_border));
//                                }
                            }
                        })
                        .setDuration(DEFAULT_ANIMATION_DURATION_MS);

                TransitionManager.beginDelayedTransition(parent, visibilitySet);
                guideText.setVisibility(View.GONE);
            });
        });
    }

    /**
     * A tiny helper to avoid nested callbacks when multiple animations need to run sequentially.
     */
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
        private Runnable onComplete;

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

        public Sequencer thenDelay(long delayMs, @NonNull Runnable stepAfterDelay) {
            steps.add(next -> runOnMainThreadDelayed(delayMs, () -> {
                stepAfterDelay.run();
                next.run();
            }));
            return this;
        }

        public Sequencer onComplete(@Nullable Runnable onComplete) {
            this.onComplete = onComplete;
            return this;
        }

        public void start() {
            runOnMainThread(this::runNext);
        }

        private void runNext() {
            Step step = steps.poll();
            if (step == null) {
                if (onComplete != null) onComplete.run();
                return;
            }

            try {
                step.run(() -> runOnMainThread(this::runNext));
            } catch (Throwable t) {
                Log.e(TAG, "Sequencer step failed", t);
                if (onComplete != null) onComplete.run();
            }
        }
    }

    private static abstract class SimpleTransitionListener implements Transition.TransitionListener {
        boolean done = false;

        abstract void onAnimationEnd();

        @Override
        public void onTransitionCancel(Transition transition) {
            if (done) return;
            done = true;
            onAnimationEnd();
        }

        @Override
        public void onTransitionEnd(Transition transition) {
            if (done) return;
            done = true;
            onAnimationEnd();
        }

        @Override
        public void onTransitionPause(Transition transition) {
        }

        @Override
        public void onTransitionResume(Transition transition) {
        }

        @Override
        public void onTransitionStart(Transition transition) {
        }
    }

}
