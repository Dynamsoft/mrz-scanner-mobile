package com.dynamsoft.dlrsample.mrzscanner.ui.main;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.dynamsoft.dlrsample.mrzscanner.R;

public class ResultAdapter extends RecyclerView.Adapter<ResultAdapter.ViewHolder> {
    private final String[] mrzResultStrings;

    public ResultAdapter(String[] mrzResultStrings) {
        this.mrzResultStrings = mrzResultStrings;
    }

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        LayoutInflater inflater = LayoutInflater.from(parent.getContext());
        return new ViewHolder(inflater.inflate(R.layout.item_mrz_result, parent, false));
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {
        String[] texts = mrzResultStrings[position].split("__");
        if(texts.length == 2) {
            holder.setText(texts[0], texts[1]);
        } else if(texts.length == 1) {
            holder.setText(texts[0],"");
        }
    }

    @Override
    public int getItemCount() {
        if(mrzResultStrings == null) {
            return 0;
        }
        return mrzResultStrings.length;
    }

    public static class ViewHolder extends RecyclerView.ViewHolder {
        TextView tvTitle;
        TextView tvValue;

        public ViewHolder(@NonNull View itemView) {
            super(itemView);
            tvTitle = itemView.findViewById(R.id.item_title);
            tvValue = itemView.findViewById(R.id.item_value);

        }

        public void setText(String title, String value) {
            tvTitle.setText(title);
            tvValue.setText(value);
        }

    }
}
