import { ReactNode } from "react";
import { TextStyle, ViewStyle } from "react-native";

export default interface props {
    onPress: any,
    isVisible: boolean | any
    touchableOpacityContainerButtonStyle: ViewStyle | ViewStyle[]
    textTitleButtonStyle: TextStyle | TextStyle[]
}