import React from 'react'

import { createStackNavigator } from '@react-navigation/stack'

import CockpitCategories from './CockpitCategories'
import StressKiller from './Stress-killer'
import Fears from './Fears'
import TopPeople from './TopPeople'
import InitialHabitList from './InitialHabitList'
import Messes from './Messes'
import SelfReview from './SelfReview'
import SelfReviewDone from './SelfReviewDone'
import Connections from './Connections'
import ToDo from './ToDo'
import Future from './Future'
import Passions from './Passions'
import Strengths from './Strengths'
// import Weaknesses from './Weaknesses'
import DailyRoutine from './DailyRoutine'
import Gratitude from './Gratitude'
import OneTime from './OneTime'
import Goals from './Goals'

const CockpitStack = createStackNavigator()

export function CockpitStackScreen() {
  return (
    <CockpitStack.Navigator
      screenOptions={() => ({
        stackAnimation: 'default',
        headerShown: false
      })}>
      <CockpitStack.Screen
        name='CockpitCategories'
        component={CockpitCategories}
      />
      <CockpitStack.Screen name='StressKiller' component={StressKiller} />
      <CockpitStack.Screen name='Fears' component={Fears} />
      <CockpitStack.Screen name='TopPeople' component={TopPeople} />
      <CockpitStack.Screen name='InitialHabitList' component={InitialHabitList} />
      <CockpitStack.Screen name='Messes' component={Messes} />
      <CockpitStack.Screen name='Connections' component={Connections} />
      <CockpitStack.Screen name='ToDo' component={ToDo} />
      {/* <CockpitStack.Screen name='Weaknesses' component={Weaknesses} /> */}
      <CockpitStack.Screen name='Passions' component={Passions} />
      <CockpitStack.Screen name='Strengths' component={Strengths} />
      <CockpitStack.Screen name='DailyRoutine' component={DailyRoutine} />
      <CockpitStack.Screen name='Gratitude' component={Gratitude} />
      <CockpitStack.Screen name='Goals' component={Goals} />
      <CockpitStack.Screen name='OneTime' component={OneTime} />
      <CockpitStack.Screen name='Future' component={Future} />
      {/*  */}
      <CockpitStack.Screen name='SelfReview' component={SelfReview} />
      <CockpitStack.Screen name='SelfReviewDone' component={SelfReviewDone} />
    </CockpitStack.Navigator>
  )
}
