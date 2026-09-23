import { TextStyle, ViewStyle } from 'react-native'

export default interface props {
  numbers: number[]
  selectedNumber: number
  touchableOpacityNumberStyle: ViewStyle | ViewStyle[]
  touchableOpacityNumberSelectedStyle: ViewStyle | ViewStyle[]
  textNumberStyle: TextStyle | TextStyle[]
  textNumberSelectedStyle: TextStyle | TextStyle[]
  onPress: any
}
