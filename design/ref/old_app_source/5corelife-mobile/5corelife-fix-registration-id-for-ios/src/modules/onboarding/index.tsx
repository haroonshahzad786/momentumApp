import React from 'react'

import { createStackNavigator } from '@react-navigation/stack'

import StepOne from './StepOne'
import StepTwo from './StepTwo'
import StepThree from './StepThree'
import StepFour from './StepFour'
import StepFive from './StepFive'
import StepSix from './StepSix'
import StepSeven from './StepSeven'
import StepEight from './StepEight'
import StepNine from './StepNine'
import StepTen from './StepTen'
import StepEleven from './StepEleven'
import { logger } from '../../helpers/logger'

const OnboardingStack = createStackNavigator()
logger.info("[<OnboardingStackScreen>]")
export function OnboardingStackScreen() {
  return (
    <OnboardingStack.Navigator
      screenOptions={() => ({
        stackAnimation: 'default',
        headerShown: false
      })}>
      <OnboardingStack.Screen name='StepOne' component={StepOne} />
      <OnboardingStack.Screen name='StepTwo' component={StepTwo} />
      <OnboardingStack.Screen name='StepThree' component={StepThree} />
      <OnboardingStack.Screen name='StepFour' component={StepFour} />
      <OnboardingStack.Screen name='StepFive' component={StepFive} />
      <OnboardingStack.Screen name='StepSix' component={StepSix} />
      <OnboardingStack.Screen name='StepSeven' component={StepSeven} />
      <OnboardingStack.Screen name='StepEight' component={StepEight} />
      <OnboardingStack.Screen name='StepNine' component={StepNine} />
      <OnboardingStack.Screen name='StepTen' component={StepTen} />
      <OnboardingStack.Screen name='StepEleven' component={StepEleven} />
    </OnboardingStack.Navigator>
  )
}
