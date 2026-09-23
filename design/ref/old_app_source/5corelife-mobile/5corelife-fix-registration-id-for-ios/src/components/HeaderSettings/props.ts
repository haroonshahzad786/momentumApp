import { TextStyle } from 'react-native'

export default interface props {
  title?: string
  subtitle?: string
  textTitleStyle: TextStyle | TextStyle[]
  textSubtitleStyle?: TextStyle | TextStyle[]
  leftArrowNavigation?: Function
  rightArrowNavigation?: Function,
  isIcon?:boolean,
  avatarTitlePath?:any
  avatarPath?:any
  primaryColor?: string
  disabled?:boolean
}
