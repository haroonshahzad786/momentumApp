import { ImageSourcePropType, TextStyle, ViewStyle } from 'react-native'

export default interface props {
  textTitleStyle: TextStyle | TextStyle[]
  textTitle: string
  actualValue?: number,
  possibleValue?: number
}
