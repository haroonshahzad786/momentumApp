import { ReactNode } from 'react'
import { ColorValue, TextStyle, ViewStyle } from 'react-native'

export default interface props {
  quizTitleStyle: TextStyle | TextStyle[]
  quizSubtitleStyle: TextStyle | TextStyle[]
  quizQuestionsHeaderStyle: TextStyle | TextStyle[]
  quizQuestionAnswerStyle: TextStyle | TextStyle[]
  quizScoreBigStyle: TextStyle | TextStyle[]
  quizScoreSmallStyle: TextStyle | TextStyle[]
  touchableOpacityContainerButtonStyle: ViewStyle | ViewStyle[]
  textTitleButtonStyle: TextStyle | TextStyle[]
  onClickOk: (...args: any[]) => void
  onCancel?: (...args: any[]) => void
  dataModal: { id: number, title: string, category: string }
  isVisible: boolean
  habitInfo: any
  setItems?: (...args: any[]) => void
  items: any[]
  goals?: boolean
  itemsNew?: boolean
  // textInputParagraphFirstOnChangeText: any,
}
