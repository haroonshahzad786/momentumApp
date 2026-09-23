import { Animated, TextStyle } from 'react-native'
import { Funeral } from '../../typescript/main';

export default interface props {
  title: string
  data: any
  inspirations: any
  screenPosY: Animated.Value
  goBack: Function
  onAdd: Function
  goals?: boolean
  // onUpdate: Function
  saveEverything: Function
  deleteItemGoals?: Function | any
  textSelector: Function,
  addItemCockpit: Function
  itemsCockpit: any
  textModal: string
  params?: any
  textScreen: string
  styleBack: TextStyle | TextStyle[]
  items: any[]
}
