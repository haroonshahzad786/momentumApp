import 'react-native-gesture-handler'
import {AppRegistry, Platform} from 'react-native';
import App from './App';
import {name as appName} from './app.json';
import PushNotificationIOS from "@react-native-community/push-notification-ios";
import PushNotification, {Importance} from "react-native-push-notification";
import { logger } from './src/helpers/logger';

PushNotification.createChannel({
    channelId: 'com.momentum',
    channelName: '5corelife',
    importance: Importance.HIGH,
    vibrate: true,
})

PushNotification.configure({
    onRegister: function (token) {
      logger.info("TOKEN:", token);
    },
    onNotification: function (notification) {
      logger.info("NOTIFICATION:", notification);
      notification.finish(PushNotificationIOS.FetchResult.NoData);
    },
  
    // IOS ONLY (optional): default: all - Permissions to register.
    permissions: {
      alert: true,
      badge: true,
      sound: true,
    },
    popInitialNotification: true,
    requestPermissions: Platform.OS === 'ios',
  });

AppRegistry.registerComponent(appName, () => App);
