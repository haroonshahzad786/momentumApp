import { Animated, TextStyle } from 'react-native'
import { Funeral } from '../../typescript/main';

export default interface props {
  title: string
  data: any
  inspirations: any
  screenPosY: Animated.Value
  goBack: Function
  onAdd: Function
  // onUpdate: Function
  saveEverything: Function
  textSelector: Function,
  addItemCockpit: Function
  itemsCockpit: any
  textModal: string
  params?: any
  textScreen: string
  styleBack: TextStyle | TextStyle[]
  tutorial?: boolean
  navigateToNextStep?:any
  nextStep?:number
}
