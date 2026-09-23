import { ReactNode } from 'react'
import { ColorValue, TextStyle, ViewStyle } from 'react-native'

export default interface props {
  index: number
  viewContainerStyle: ViewStyle | ViewStyle[]
  textNumberStyle: TextStyle | TextStyle[]
  textInputName: string
  textInputNameStyle: TextStyle | TextStyle[]
  // textInputNameOnChangeText: any
  textInputNameOnSubmitEditing: any
  placeholder: string
  placeholderColor: ColorValue
  imageRight: ReactNode
  imageLine: ReactNode | null
  setDataModal: (...args: any[]) => void
  setModalVisible: (...args: any[]) => void
  item: any
  idx?: boolean
}
