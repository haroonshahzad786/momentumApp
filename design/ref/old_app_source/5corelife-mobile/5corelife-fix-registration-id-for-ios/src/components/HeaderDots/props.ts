import { TextStyle } from "react-native";

export default interface props {
  dotsCount: number
  activeDotIndex: number
  activeDotStyle?: TextStyle | TextStyle[]
  dotStyle?: TextStyle | TextStyle[]
  onBackButton?: Function
  onHelpButton?: Function
  goHome?: Function
  disabled?:boolean
}
