import React, { useEffect } from 'react'

import { NavigationContainer } from '@react-navigation/native'
import { createStackNavigator } from '@react-navigation/stack'

import KeyboardAwareScrollView from '../../components/KeyboardAwareScrollView'
import { AuthStackScreen } from '../auth'
import { CockpitStackScreen } from '../cockpit'
import { ConfigurationStackScreen } from '../configuration'
import { OnboardingStackScreen } from '../onboarding'
import { CoreStackScreen } from '../core'
import { DashboardStackScreen } from '../dashboard'
import { useRecoilValue } from 'recoil'
import { localDataAtom, storageAtom, userRetrieveAtom } from '../../recoil/atoms'
import { logger } from '../../helpers/logger'

const MainStack = createStackNavigator()
const RootStack = createStackNavigator()
logger.info("[<Navigator>]")
function MainStackScreen() {
  const storage = useRecoilValue(storageAtom);
  const localData = useRecoilValue(localDataAtom);
  const userRetrieve = useRecoilValue(userRetrieveAtom);
  const onBoardingActive = userRetrieve?.value?.user_profile.onboarding || storage?.value?.onboarding;

  return (
    <MainStack.Navigator screenOptions={{ headerShown: false }}>
      {(storage.value.token && localData.init) ? (
        !onBoardingActive ? (
          <MainStack.Screen
            name='OnboardingStackScreen'
            component={OnboardingStackScreen}
          />
        ) : (
          <>
            <MainStack.Screen
              name='DashboardStackScreen'
              component={DashboardStackScreen}
            />
            <MainStack.Screen
              name='CockpitStackScreen'
              component={CockpitStackScreen}
            />
            <MainStack.Screen
              name='ConfigurationStackScreen'
              component={ConfigurationStackScreen}
            />
            <MainStack.Screen
              name='CoreStackScreen'
              component={CoreStackScreen}
            />
          </>
        )) : (
        <MainStack.Screen name='AuthStackScreen' component={AuthStackScreen} />
      )}
    </MainStack.Navigator>
  )
}

export default function RootStackScreen() {
  return (
    <KeyboardAwareScrollView>
      <NavigationContainer>
        <RootStack.Navigator
          screenOptions={{ headerShown: false, animationEnabled: false }}>
          <RootStack.Screen
            name='MainStackScreen'
            component={MainStackScreen}
          />
        </RootStack.Navigator>
      </NavigationContainer>
    </KeyboardAwareScrollView>
  )
}
