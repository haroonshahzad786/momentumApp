import { ReactNode } from 'react'
import { ColorValue, TextStyle, ViewStyle } from 'react-native'

export default interface props {
  touchableOpacityContainerButtonStyle: ViewStyle | ViewStyle[]
  textTitleButtonStyle: TextStyle | TextStyle[]
  imageMonitor: any
  imageMask?: any | null
  children: ReactNode
  textTitle: string
  onClick: (...args: any[]) => void
  onCancel?: (...args: any[]) => void
  // isModalVisibled?: (...args: any[]) => void
  isVisible: boolean
  heightOffset?: number
  hasVeil?: boolean
}
