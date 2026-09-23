import { StyleSheet } from 'react-native'

import { vh, vw } from '../../../helpers/dimensions'

export default StyleSheet.create({
  indicatorContainer:{
    alignItems:'center',
    justifyContent:'center'
  },

  highlightContainer:{
    height: vh(18),
    width: vh(18),
  },

  arrowSelecting:{
    width: vh(2),
    // backgroundColor:'blue',
  },
  arrowContainer:{
    position:'absolute',
    width:vh(25),
    height:vh(10),
    flexDirection:'row',
    alignItems:'center',
    // backgroundColor:'red',
  },
  arrowTwo:{
    opacity:0.5,
  },
  arrowThree:{
    opacity:0.2,
  },
})
