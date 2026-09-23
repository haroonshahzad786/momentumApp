import { TextStyle, ViewStyle } from "react-native";

export default interface props {
  title?: string
  subtitle?: string
  slideScreens?: number
  slideActive?: number
  fromBottom?: boolean
  titleOnBottom?: boolean,
  toMiddle?: boolean,
  toTop?: boolean
  reverse?: boolean
  fontSize?: ViewStyle | ViewStyle[] | TextStyle | TextStyle[]
  disabled?:boolean
}
