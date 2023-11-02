package com.optimove.flutter.events;

import androidx.annotation.NonNull;

import com.optimove.android.optimobile.PushMessage;

import java.util.HashMap;
import java.util.Map;

public class PushReceivedEvent extends PushEvent{

    public PushReceivedEvent(@NonNull PushMessage pushMessage) {
        super(pushMessage);
    }

    public Map<String, Object> toMap(){
        Map<String, Object> event = new HashMap<>(2);
        event.put("type", "push.received");
        event.put("data", pushMessageToMap(null));
        return event;
    }
}
