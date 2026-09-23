import { ReactNode } from 'react'
import { TextStyle, ViewStyle } from 'react-native'

export default interface props {
  textTitle: string
  textTitleStyle: TextStyle | TextStyle[]
  iconRight: ReactNode
  textInputParagraphFirst?: string
  textParagraphSecond?: string
  textInputParagraphStyle: TextStyle | TextStyle[]
  textInputParagraphFirstOnChangeText: any
  textParagraphDividerStyle: TextStyle | TextStyle[]
  touchableOpacityContainerButtonStyle: ViewStyle | ViewStyle[]
  touchableOpacityContainerButtonOnPress: any
  textTitleButton: string
  textTitleButtonStyle: TextStyle | TextStyle[]
  isVisible: boolean
}
