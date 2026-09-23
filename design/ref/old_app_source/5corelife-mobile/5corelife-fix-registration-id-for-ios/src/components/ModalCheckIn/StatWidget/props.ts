import { ReactNode } from 'react'
import { ColorValue, TextStyle, ViewStyle } from 'react-native'

export default interface props {
  statsNumbersStyle: TextStyle | TextStyle[]
  statImage: any
  statValue: number
  isLocked: boolean
}
