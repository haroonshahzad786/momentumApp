import { ReactNode } from 'react'
import { ColorValue, TextStyle, ViewStyle } from 'react-native'

export default interface props {
  titleStyle: TextStyle | TextStyle[]
  statsNumbersStyle: TextStyle | TextStyle[]
  rewardTitleStyle: TextStyle | TextStyle[]
  rewardNumberStyle: TextStyle | TextStyle[]
  checkInNumbersBigStyle: TextStyle | TextStyle[]
  checkInNumbersSmallStyle: TextStyle | TextStyle[]
  checkInDescriptionStyle: TextStyle | TextStyle[]
  touchableOpacityContainerButtonStyle: ViewStyle | ViewStyle[]
  textTitleButtonStyle: TextStyle | TextStyle[]
  onClickOk: (...args: any[]) => void
  isVisible: boolean,
  cores: any
  days: any
  momentum: any
  statusGoal: string
}
