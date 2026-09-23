import { TextStyle, ViewStyle } from 'react-native'

export default interface props {
  touchableOpacityContainerButtonStyle: ViewStyle | ViewStyle[]
  textTitleButtonStyle: TextStyle | TextStyle[]
  onClickOk: (...args: any[]) => void
  textMainHeader: string
  textContentHeader: string
  textContentInfo: string
  isVisible: boolean
  isModalVisibled?: (...args: any[]) => void
}
