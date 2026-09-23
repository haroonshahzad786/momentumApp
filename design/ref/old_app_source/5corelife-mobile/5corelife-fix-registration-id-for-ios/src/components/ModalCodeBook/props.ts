import { ReactNode } from 'react'
import { ColorValue, TextStyle, ViewStyle } from 'react-native'

export default interface props {
  textTitle: string
  textTitleStyle: TextStyle | TextStyle[]
  reference?: any
  textInput: string
  textInputStyle: any
  keyboardType?:
  | 'default'
  | 'email-address'
  | 'numeric'
  | 'phone-pad'
  | 'number-pad'
  | 'decimal-pad'
  autoCapitalize?: 'none' | 'sentences' | 'words' | 'characters'
  isSecure?: boolean
  maxLength: number
  onChangeText: any
  cancelButtonStyle?: ViewStyle | ViewStyle[]
  cancelButtonImage: ReactNode
  onCancel: any
  okButtonImage: ReactNode
  okButtonStyle?: ViewStyle | ViewStyle[]
  onOk: any
  isVisible: boolean
}
