import { ImageStyle, ViewStyle } from "react-native";

export default interface props {
  containerStyle?: ViewStyle | ViewStyle[]
  highlightStyle?: ImageStyle | ImageStyle[]
  arrowContainerStyle?: ViewStyle | ViewStyle[]
  withoutHighlight?: boolean
}
