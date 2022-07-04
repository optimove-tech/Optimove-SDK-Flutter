package com.optimove.flutter.optimove_sdk_flutter_example;

import io.flutter.embedding.android.FlutterActivity;

import android.content.Intent;
import android.os.Bundle;

import com.optimove.android.Optimove;

public class MainActivity extends FlutterActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        Optimove.getInstance().seeIntent(getIntent(), savedInstanceState);
    }

    @Override
    public void onWindowFocusChanged(boolean hasFocus) {
        super.onWindowFocusChanged(hasFocus);
        Optimove.getInstance().seeInputFocus(hasFocus);
    }

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        Optimove.getInstance().seeIntent(intent);
    }
}
