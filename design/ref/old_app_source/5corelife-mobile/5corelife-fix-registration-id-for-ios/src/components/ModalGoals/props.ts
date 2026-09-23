import { ReactNode } from 'react';
import { TextStyle, ViewStyle } from 'react-native'

export default interface props {
  textTitle: string
  textDescription: string
  textTitleStyle: TextStyle | TextStyle[]
  touchableOpacityButtonImage: ReactNode
  touchableOpacityButtonStyle: ViewStyle | ViewStyle[]
  touchableOpacityButtonOnPress: any
  isVisible: boolean
}
