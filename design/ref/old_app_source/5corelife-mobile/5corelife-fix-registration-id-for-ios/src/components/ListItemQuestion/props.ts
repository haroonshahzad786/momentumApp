import { ColorValue, TextStyle } from 'react-native'

export default interface props {
  index: number
  question: {
    title: string
  }
  textTitleStyle: TextStyle | TextStyle[]
  textInputAnswer: string
  textInputAnswerStyle: TextStyle | TextStyle[]
  textInputAnswerOnChangeText: any
  placeholder: string
  placeholderColor: ColorValue
}
