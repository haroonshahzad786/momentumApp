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
  setValue: (...args: any[]) => void
  value: any
  answer1: any
  answer2: any
  quiz: { quiz: boolean, quiz1: boolean, quiz2: boolean }
  core: string
  isVisible: boolean
}
