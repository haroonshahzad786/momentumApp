import { TextStyle } from "react-native";

export default interface props {
  onPress: any,
  selectedId?: string
  quizScoreSmallStyle: TextStyle | TextStyle[]
  quizQuestionAnswerStyle: TextStyle | TextStyle[]
  quizQuestionDescriptionStyle: TextStyle | TextStyle[]
  answers: Array<{
    id: string
    answer: string,
    point: number
  }> | undefined
}
