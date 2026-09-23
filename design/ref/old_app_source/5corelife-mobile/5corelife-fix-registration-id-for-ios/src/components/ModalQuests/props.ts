import { ReactNode } from 'react'
import { ColorValue, TextStyle, ViewStyle } from 'react-native'

export default interface props {
  daysNumberStyle: TextStyle | TextStyle[]
  daysDescriptionStyle: TextStyle | TextStyle[]
  questDescriptionStyle: TextStyle | TextStyle[]
  touchableOpacityContainerButtonStyle: ViewStyle | ViewStyle[]
  textTitleButtonStyle: TextStyle | TextStyle[]
  // mode: 'new' | 'failed' | 'completed'
  onClickOk: (...args: any[]) => void
  // isModalVisibled?: (...args: any[]) => void
  isVisible: boolean
  days?: string | number | undefined
  currentCheckIn?: string | undefined | any
  questOrMission?: string
  credits?: number
  quest?: any[] | any
  missions?: any[] | any
  type?: string
}
