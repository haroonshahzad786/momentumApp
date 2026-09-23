import { ImageSourcePropType, ViewStyle } from "react-native";

export default interface props {
  externalStyle: ViewStyle | ViewStyle[],
  skinColor?: string,
  wings?: string,
  turbines?: string,
  flamePower?:number,
}
