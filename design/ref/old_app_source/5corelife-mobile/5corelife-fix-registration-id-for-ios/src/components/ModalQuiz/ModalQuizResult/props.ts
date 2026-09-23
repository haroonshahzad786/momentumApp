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
  // isModalVisibled ?: (...args: any[]) => void
  isVisible: boolean
  answer1: any
  answer2: any
  answer3: any
  core: string
  back: boolean
}
