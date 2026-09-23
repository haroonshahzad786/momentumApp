import { ReactNode } from 'react'
import { TextStyle, ViewStyle } from 'react-native'

export default interface props {
  textTitle: string
  textTitleStyle: TextStyle | TextStyle[]
  cancelButtonImage: ReactNode
  cancelButtonStyle?: null | ViewStyle | ViewStyle[]
  okButtonImage: ReactNode
  okButtonStyle?: ViewStyle | ViewStyle[]
  onCancel: any
  onOk: any
  isVisible: boolean
}
