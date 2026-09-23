import { ViewStyle } from "react-native";

export default interface props {
  item: any,
  onPressAction: any,
  imageSource: any,
  maskSource: any,
  liquidSource: any,
  styleTouchable: ViewStyle | ViewStyle[],
  liquidFillPercentage:number,
  isCentered?:boolean,
  isBottom?:boolean,
  readonly?:boolean
}
