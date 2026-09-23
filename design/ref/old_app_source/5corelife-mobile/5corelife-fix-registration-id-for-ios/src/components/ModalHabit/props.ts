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
  onCancel?:(...args: any[]) => void
  isVisible: boolean
  textInputParagraphStyle: TextStyle | TextStyle[]
  // textInputParagraphFirstOnChangeText: any,
  habitInfo: any,
  isNewAdd?:boolean
  format?:boolean
  fromMorning?: boolean
}
