package com.optimove.flutter;

import android.app.Activity;
import android.app.TaskStackBuilder;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import com.optimove.android.Optimove;
import com.optimove.android.optimobile.Optimobile;
import com.optimove.android.optimobile.PushBroadcastReceiver;
import com.optimove.android.optimobile.PushMessage;
import com.optimove.flutter.events.PushOpenedEvent;
import com.optimove.flutter.events.PushReceivedEvent;

import org.json.JSONException;
import java.util.HashMap;
import java.util.Map;

public class PushReceiver extends PushBroadcastReceiver {

    @Override
    protected void onPushReceived(Context context, PushMessage pushMessage) {
        super.onPushReceived(context, pushMessage);
        OptimoveFlutterPlugin.eventSink.send(new PushReceivedEvent(pushMessage).toMap(), false);
    }
    
    @Override
    protected void onPushOpened(Context context, PushMessage pushMessage) {
        try {
            Optimove.getInstance().pushTrackOpen(pushMessage.getId());
        } catch (Optimobile.UninitializedException ignored) {
        }

        PushReceiver.handlePushOpen(context, pushMessage, null);
    }

    @SuppressWarnings("unchecked")
    public static void handlePushOpen(Context context, PushMessage pushMessage, String actionId) {
        PushReceiver pr = new PushReceiver();
        Intent launchIntent = pr.getPushOpenActivityIntent(context, pushMessage);

        if (null == launchIntent) {
            return;
        }

        ComponentName component = launchIntent.getComponent();
        if (null == component) {
            return;
        }

        Class<? extends Activity> cls = null;
        try {
            cls = (Class<? extends Activity>) Class.forName(component.getClassName());
        } catch (ClassNotFoundException e) {
            /* Noop */
        }

        // Ensure we're trying to launch an Activity
        if (null == cls) {
            return;
        }

        Activity currentActivity = OptimoveFlutterPlugin.currentActivityRef.get();
        if (null != currentActivity) {
            Intent existingIntent = currentActivity.getIntent();
            addDeepLinkExtras(pushMessage, existingIntent);
        }

        if (null != pushMessage.getUrl()) {
            launchIntent = new Intent(Intent.ACTION_VIEW, pushMessage.getUrl());

            addDeepLinkExtras(pushMessage, launchIntent);

            TaskStackBuilder taskStackBuilder = TaskStackBuilder.create(context);
            taskStackBuilder.addParentStack(component);
            taskStackBuilder.addNextIntent(launchIntent);
            taskStackBuilder.startActivities();
        } else {
            launchIntent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP);

            addDeepLinkExtras(pushMessage, launchIntent);

            context.startActivity(launchIntent);
        }

        OptimoveFlutterPlugin.eventSinkDelayed.send(new PushOpenedEvent(pushMessage).toMap(actionId));
    }
}