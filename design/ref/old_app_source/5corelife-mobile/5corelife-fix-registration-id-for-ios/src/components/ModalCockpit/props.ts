import { ReactNode } from 'react'
import { ColorValue, TextStyle, ViewStyle } from 'react-native'

export default interface props {
  quizTitleStyle: TextStyle | TextStyle[]
  quizSubtitleStyle: TextStyle | TextStyle[]
  quizQuestionsHeaderStyle: TextStyle | TextStyle[]
  quizQuestionAnswerStyle: TextStyle | TextStyle[]
  quizQuestionDescriptionStyle: TextStyle | TextStyle[]
  quizScoreBigStyle: TextStyle | TextStyle[]
  quizScoreSmallStyle: TextStyle | TextStyle[]
  touchableOpacityContainerButtonStyle: ViewStyle | ViewStyle[]
  textTitleButtonStyle: TextStyle | TextStyle[]
  onClickOk: (...args: any[]) => void
  onCancel?: (...args: any[]) => void
  setItems?: (...args: any[]) => void
  dataModal: { id: number, title: string, category: string }
  items: any[]
  isVisible: boolean
  // textInputParagraphFirstOnChangeText: any,
  habitInfo: any,
  goals?: boolean
  itemsNew?: boolean
}
