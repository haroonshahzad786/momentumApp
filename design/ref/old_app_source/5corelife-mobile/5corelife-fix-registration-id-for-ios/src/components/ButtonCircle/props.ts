import { ColorValue, TextStyle, ViewStyle } from 'react-native'

export default interface props {
  titlePath?: any
  iconPath: any
  containerButtonHeaderStyle: ViewStyle | ViewStyle[]
  containerButtonTitleStyle?: TextStyle | TextStyle[]
  containerButtonRocket?: TextStyle | TextStyle[] | any
  infoText?: string | any
  onPress: any
  isBlocked?: boolean
  unlocked?: boolean
  isActive?: boolean | null,
  hasCoin?: boolean,
  hasImageShadow?: boolean,
  shadowPath?: any
  wings?: any
  fontSize?: number
  size?: TextStyle | TextStyle[]
  coinActived?: boolean | any
}
