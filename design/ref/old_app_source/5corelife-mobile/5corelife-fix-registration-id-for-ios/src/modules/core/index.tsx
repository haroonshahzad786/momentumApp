import React from 'react'

import { createStackNavigator } from '@react-navigation/stack'

import CheckHabits from './CheckHabits'
// import CheckHabitsAchieved from './CheckHabitsAchieved'
import SetHabits from './SetHabits'
import SetupHabits from './SetupHabits'
import InitHabits from './InitHabits'

const CoreStack = createStackNavigator()

export function CoreStackScreen() {
  return (
    <CoreStack.Navigator
      screenOptions={() => ({
        stackAnimation: 'default',
        headerShown: false
      })}>
      <CoreStack.Screen name='InitHabits' component={InitHabits} />
      <CoreStack.Screen name='SetHabits' component={SetHabits} />
      <CoreStack.Screen name='SetupHabits' component={SetupHabits} />
      <CoreStack.Screen name='CheckHabits' component={CheckHabits} />
      {/* <CoreStack.Screen
        name='CheckHabitsAchieved'
        component={CheckHabitsAchieved}
      /> */}
    </CoreStack.Navigator>
  )
}
