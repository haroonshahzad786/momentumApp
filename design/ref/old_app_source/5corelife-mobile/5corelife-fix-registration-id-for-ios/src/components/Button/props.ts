import { ColorValue, TextStyle, ViewStyle } from 'react-native'

export default interface props {
  textTitle: string
  textTitleStyle: TextStyle | TextStyle[]
  touchableOpacityContainerStyle: ViewStyle | ViewStyle[]
  spinnerSize?: number
  spinnerColor?: ColorValue
  isLoading?: boolean
  onPress: any
  disabled?:boolean
}
