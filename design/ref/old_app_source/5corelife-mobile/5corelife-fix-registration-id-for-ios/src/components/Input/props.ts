import { ColorValue } from 'react-native'

export default interface props {
  reference?: any
  textInput: string
  textInputStyle: any
  textInputPlaceholder: string
  textInputPlaceholderColor: ColorValue
  keyboardType?:
    | 'default'
    | 'email-address'
    | 'numeric'
    | 'phone-pad'
    | 'number-pad'
    | 'decimal-pad'
  autoCapitalize?: 'none' | 'sentences' | 'words' | 'characters'
  isSecure?: boolean
  backgroundColor: ColorValue
  borderRadius: number
  borderWidth?: number
  borderColor?: ColorValue
  onChangeText: any
  onSubmitEditing?: () => void
  onFocus?: () => void
  onBlur?: () => void
}
