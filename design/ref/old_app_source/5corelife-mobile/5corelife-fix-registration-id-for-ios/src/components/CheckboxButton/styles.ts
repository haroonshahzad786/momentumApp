import { StyleSheet } from 'react-native'

import { vh, vw } from '../../helpers/dimensions'

export default StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center'
  },
  textSwitch: {
    marginBottom: -vh(0.5),
    paddingHorizontal: vw(2.5)
  },
  checkbox:{
    // borderRadius:50,
    // transform: [{ scaleX: vw(0.15+0.15) }, { scaleY: vh(0.2) }] 
  },
  formedHabitButton:{
    alignItems: 'center',
    justifyContent:'space-between',
    paddingHorizontal: vh(2),   
    paddingVertical: vw(2),
    borderRadius:50,
    marginHorizontal:vh(2),
    flexDirection:'row',
    width:vw(40)
  },
  imageButton: {
    width: vh(2),
    height: vh(2),
  },
  bubbleBg:{
    paddingVertical: vw(1),
    paddingHorizontal:vw(2),
    borderRadius:550,
    width: vh(4),
    height:  vh(4),
    justifyContent:'center',
    alignItems:'center'
  }
})
