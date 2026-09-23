import { Dimensions } from 'react-native'
import {
  getBottomSpace,
  getStatusBarHeight
} from 'react-native-iphone-x-helper'

const { width, height } = Dimensions.get('screen')

export const vw = (percentage: number) => {
  return (width / 100) * percentage
}

export const vh = (percentage: number) => {
  return ((height - getStatusBarHeight() - getBottomSpace()) / 100) * percentage
}
