import { ColorValue, TextStyle } from 'react-native'

export default interface props {
  category: {
    name: string
    enabled: boolean
    mantra: boolean
  }
  // category: {
  //   title: string
  //   isEnabled: boolean
  //   mantra: boolean
  // }
  textTitleStyle: TextStyle | TextStyle[]
  backgroundColor: ColorValue
  onPress: any
  openMantra: Function
}
