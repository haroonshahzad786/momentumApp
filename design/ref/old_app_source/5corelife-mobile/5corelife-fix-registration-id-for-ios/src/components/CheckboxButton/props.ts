import { ReactNode } from 'react'
import { ColorValue, TextStyle, ViewStyle } from 'react-native'

export default interface props {
  onPress: any,
  labelFontStyle: TextStyle | TextStyle[],
  label: string,
  backgroundColor: string,
  initialState?: boolean
  disabled:boolean
}
