import { ColorValue, TextStyle, ViewStyle } from 'react-native'

export default interface props {
  avatarPath?:any
  primaryColor: string
  hasBubble?: boolean
  isActive?:boolean
  textHeader: string
  isContentList?:boolean
  content: any
  firstHeaderColumn:string
  secondHeaderColumn?:string
  onEditing: any,
}
