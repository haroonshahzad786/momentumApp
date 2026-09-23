import { ReactNode } from 'react'
import { ColorValue, TextStyle, ViewStyle } from 'react-native'

export default interface props {
  textTitle: string
  textTitleStyle: TextStyle | TextStyle[]
  textInput: string
  textInputStyle: TextStyle | TextStyle[]
  textInputOnChangeText: any
  textSwitchOff: string
  textSwitchOn: string
  textSwitchStyle: TextStyle | TextStyle[]
  switchTrackColor: {
    false: ColorValue
    true: ColorValue
  }
  switchThumbColor: ColorValue
  switchIsEnabled: boolean
  touchableOpacityButtonImage: ReactNode
  touchableOpacityButtonStyle: ViewStyle | ViewStyle[]
  touchableOpacityButtonOnPress: any
  isVisible: boolean,
  switchOnChange: any
}
