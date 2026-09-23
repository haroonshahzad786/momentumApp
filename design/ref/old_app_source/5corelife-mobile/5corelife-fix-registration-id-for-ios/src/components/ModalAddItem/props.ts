import { ReactNode } from 'react'
import { TextStyle, ViewStyle, ColorValue } from 'react-native'

export default interface props {
  textTitle: string
  textTitleStyle: TextStyle | TextStyle[]
  textInputName?: string
  textInputNameStyle: TextStyle | TextStyle[]
  textInputNameOnChangeText: any
  textInputNameOnSubmitEditing: any
  placeholder: string
  placeholderColor: ColorValue
  cancelButtonImage: ReactNode
  cancelButtonStyle?: null | ViewStyle | ViewStyle[]
  okButtonImage: ReactNode
  okButtonStyle?: ViewStyle | ViewStyle[]
  onCancel: any
  onOk: (...args: any[]) => void | any
  isVisible: { visibled: boolean, edit: boolean }
  setDataModal: (...args: any[]) => void
  dataModal: any
}
