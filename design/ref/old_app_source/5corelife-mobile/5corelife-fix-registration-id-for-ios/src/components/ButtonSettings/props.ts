import { ReactNode } from 'react'
import { TextStyle, ViewStyle } from 'react-native'

export default interface props {
  touchableOpacityContainerStyle: ViewStyle | ViewStyle[]
  touchableOpacityContainerOnPress: any
  textTitle: string
  textTitleStyle: TextStyle | TextStyle[]
  imageRight: ReactNode
  disabled?:boolean
}
