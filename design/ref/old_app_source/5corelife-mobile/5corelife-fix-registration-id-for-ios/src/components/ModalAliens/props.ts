import { ReactNode } from "react";
import { TextStyle, ViewStyle } from "react-native";

export default interface props {
    navigate: any
    okButtonImage: ReactNode,
    destination: string | any
    styleAlien: TextStyle | TextStyle[]
    onclickOnAliens: Function
}