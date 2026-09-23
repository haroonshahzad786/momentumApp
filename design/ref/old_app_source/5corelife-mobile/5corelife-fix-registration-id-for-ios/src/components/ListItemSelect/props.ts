import { ReactNode } from 'react'
import { ColorValue, TextStyle, ViewStyle } from 'react-native'

export default interface props {
  index: number
  viewContainerStyle: ViewStyle | ViewStyle[]
  textNumberStyle: TextStyle | TextStyle[]
  textInputName: { name: string, category: string, id: number, length?: number, score?: number }
  textInputNameStyle: TextStyle | TextStyle[]
  // textInputNameOnChangeText: any
  textInputNameOnSubmitEditing: any
  placeholder: string
  placeholderColor: ColorValue
  imageRight: ReactNode
  imageLine: ReactNode | null
  setModalVisible: (...args: any[]) => void
  setDataModal: (...args: any[]) => void
  setModalVisibleDelete?: any
  idx?: boolean
  goals?: boolean
}
