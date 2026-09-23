import { TextStyle, ViewStyle } from 'react-native'

export default interface props {
  touchableOpacityContainerStyle: ViewStyle | ViewStyle[]
  touchableOpacityContainerOnPress: any
  touchableOpacityContainerOnLongPress?: any
  textTitle: string
  textTitleStyle: TextStyle | TextStyle[]
  disabled?: boolean
}
