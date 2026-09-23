import React from 'react'

import { createStackNavigator } from '@react-navigation/stack'

import ForgotPassword from './ForgotPassword'
import ForgotPasswordCode from './ForgotPasswordCode'
import ForgotPasswordSuccess from './ForgotPasswordSuccess'
import Login from './Login'
import Register from './Register'
import RegisterSuccess from './RegisterSuccess'

const AuthStack = createStackNavigator()

export function AuthStackScreen() {
  return (
    <AuthStack.Navigator
      screenOptions={() => ({
        stackAnimation: 'default',
        headerShown: false
      })}>
      <AuthStack.Screen name='Login' component={Login} />
      <AuthStack.Screen name='Register' component={Register} />
      <AuthStack.Screen name='RegisterSuccess' component={RegisterSuccess} />
      <AuthStack.Screen name='ForgotPassword' component={ForgotPassword} />
      <AuthStack.Screen
        name='ForgotPasswordCode'
        component={ForgotPasswordCode}
      />
      <AuthStack.Screen
        name='ForgotPasswordSuccess'
        component={ForgotPasswordSuccess}
      />
    </AuthStack.Navigator>
  )
}
