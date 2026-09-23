import { ReactNode } from 'react'
import { ColorValue, TextStyle, ViewStyle } from 'react-native'

export default interface props {
  quizTitleStyle?: TextStyle | TextStyle[]
  quizSubtitleStyle: TextStyle | TextStyle[]
  quizQuestionsHeaderStyle: TextStyle | TextStyle[]
  touchableOpacityContainerButtonStyle: ViewStyle | ViewStyle[]
  total: ViewStyle | ViewStyle[] | any
  textTitleButtonStyle: TextStyle | TextStyle[]
  onClickOk: any 
  clickWhat: (...args: any[]) => void
  // isModalVisibled?: (...args: any[]) => void
  isVisible: boolean,
  result: any[]
}
