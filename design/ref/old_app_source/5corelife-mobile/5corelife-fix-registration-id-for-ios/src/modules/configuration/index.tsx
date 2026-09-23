import React from 'react'

import { createStackNavigator } from '@react-navigation/stack'

import Bonus from './Bonus'
import Improvements from './Improvements'
import ImprovementTurbines from './ImprovementTurbines'
import ImprovementWings from './ImprovementWings'
import Leaderboard from './Leaderboard'
import Overview from './Overview'
import Profile from './Profile'
import CaptainsLog from './CaptainsLog'
import Settings from './Settings'
import Disclaimer from './Disclaimer'
import Credits from './Credits'
import StorageScreen from './Storage'
import Trophies from './Trophies'
import Help from './Help'
import ImprovementArmors from './ImprovementArmors'

const ConfigurationStack = createStackNavigator()

export function ConfigurationStackScreen() {
  return (
    <ConfigurationStack.Navigator
      screenOptions={() => ({
        stackAnimation: 'default',
        headerShown: false,
      })}>
      <ConfigurationStack.Screen name='Bonus' component={Bonus} />
      <ConfigurationStack.Screen name='Improvements' component={Improvements} />
      <ConfigurationStack.Screen
        name='ImprovementArmors'
        component={ImprovementArmors}
      />
      <ConfigurationStack.Screen
        name='ImprovementTurbines'
        component={ImprovementTurbines}
      />
      <ConfigurationStack.Screen
        name='ImprovementWings'
        component={ImprovementWings}
      />
      <ConfigurationStack.Screen name='Leaderboard' component={Leaderboard} />
      <ConfigurationStack.Screen name='Overview' component={Overview} />
      <ConfigurationStack.Screen name='Profile' component={Profile} />
      <ConfigurationStack.Screen name='CaptainsLog' component={CaptainsLog} />
      <ConfigurationStack.Screen name='Settings' component={Settings} />
      <ConfigurationStack.Screen name='Disclaimer' component={Disclaimer} />
      <ConfigurationStack.Screen name='Credits' component={Credits} />
      <ConfigurationStack.Screen name='Storage' component={StorageScreen} />
      <ConfigurationStack.Screen name='Trophies' component={Trophies} />
      <ConfigurationStack.Screen name='Help' component={Help} />
    </ConfigurationStack.Navigator>
  )
}
