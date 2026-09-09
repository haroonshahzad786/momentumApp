import React, { useEffect } from 'react'
import { LogBox, Platform } from 'react-native'
import RNBootSplash from 'react-native-bootsplash'
import { RecoilRoot } from 'recoil'
import Initializer from './src/modules/shared/Initializer'
import Navigator from './src/modules/shared/Navigator'
import messaging from '@react-native-firebase/messaging';
import { ShowNotificationIOS } from './src/helpers/internalDataManagement'
import { logger } from './src/helpers/logger'

export default function App() {

  useEffect(() => {
    // IT WILL RUN WHEN THIS APPLICATION IS OPEN
    const unsubscribe: any = messaging().onMessage(async (remoteMessage: any) => {
      const { notification } = remoteMessage;
      if (Platform.OS === 'ios') ShowNotificationIOS(notification) 
      logger.info('A new FCM message arrived!', JSON.stringify(remoteMessage));
    });

    // THIS's FOR THE TOPIC
    const topicSubscribe: any =  messaging().subscribeToTopic('Miguelangel')
      .then(response => logger.info("topicSubscribe Migel Angel: ",response))
      .catch(error => logger.error("Topic subscription error: ", error));

    // IT WILL RUN WHEN THIS APPLICATION IS CLOSE
    const backSubscribe: any =  messaging().setBackgroundMessageHandler(async remoteMessage => {
      logger.info('A new FCM message arrived CLOSE!', JSON.stringify(remoteMessage));
    });

    (async () => {
      if (Platform.OS === 'ios') {
        // ACCORDING TO THE DOCUMENTATION FOR ANDROID IT ISN'T NECESARY (PERMISSIONS)
        const authStatus = await messaging().requestPermission();
        const enabled =
          authStatus === messaging.AuthorizationStatus.AUTHORIZED ||
          authStatus === messaging.AuthorizationStatus.PROVISIONAL;
        logger.info("Request permission for IOS enabled: ", enabled, "authStatus: ", authStatus, " messaging: ", messaging)
        if (enabled) {
          await messaging().registerDeviceForRemoteMessages();
          unsubscribe();
          topicSubscribe;
          backSubscribe
        }
      }
    })()

    return () => {
      unsubscribe();
      topicSubscribe;
      backSubscribe
    };
  }, [])

  useEffect(() => {
    RNBootSplash.show()
    let Sound = require('react-native-sound')

    const soundAirlock = new Sound(
      require('./src/assets/sounds/Menu_Select_00.mp3'),
      () => {
        soundAirlock.play((success: any) => logger.info("soundAirlock",success))
      }
    )
    // 1. Ignore virtualized lists warning. Remove when fixed by RN team.
    // 2. Ignore unique key prop in lists warning. Remove when fixed by react-native-chart-kit team.
    // 3. Ignore non-serializable values in hardcoded news detail.
    // 4. Ignore duplicated atom keys due to hot module replacement.
    // 5. Ignore RNPickerSelect update problem.
    // 6. Ignore RNPickerSelect update problem.
    // 7. Ignore RCTBridge required dispatch_sync
    LogBox.ignoreLogs([
      'VirtualizedLists should never be nested',
      'Each child in a list should have a unique',
      'Non-serializable values were found',
      'Duplicate atom key',
      'Warning: Cannot update a component',
      'Sending `onAnimatedValueUpdate` with no listeners',
      'RCTBridge required dispatch_sync'
    ])
  })

  return (
    <>
      <RecoilRoot>
        <Initializer>
          <Navigator />
        </Initializer>
      </RecoilRoot>
    </>
  )
}
