package com.optimove.flutter.events;

import androidx.annotation.NonNull;

import com.optimove.android.optimobile.PushMessage;

import java.util.HashMap;
import java.util.Map;

public class PushOpenedEvent extends PushEvent {
    public PushOpenedEvent(@NonNull PushMessage pushMessage) {
        super(pushMessage);
    }

    public Map<String, Object> toMap(String actionId) {
        Map<String, Object> event = new HashMap<>(2);
        event.put("type", "push.opened");
        event.put("data", pushMessageToMap(actionId));

        return event;
    }


}
