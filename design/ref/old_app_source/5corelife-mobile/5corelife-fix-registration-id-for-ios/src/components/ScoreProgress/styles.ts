import { StyleSheet } from 'react-native'

import { vh, vw } from '../../helpers/dimensions'

export default StyleSheet.create({
  viewContainer: {
    justifyContent: 'center',
    alignItems: 'center'
  },

  textTitle: {
  },

  imageProgress: {
    width: vw(65),
    height: vh(5.25),
  },
  imageProgressMask:{
    width: vw(68),
    height: vh(5.25),
    // justifyContent:'flex-start',
    // alignItems:'flex-start'
  },
  imageProgressElement:{
    width: vw(64),
    height: vh(5.25),
  },
  barContainer:{
    justifyContent: 'center', 
    alignItems: 'center',
    borderRadius:50,
    overflow:'hidden',
    width: vh(32),
    height: vh(4.55),
    borderWidth:4,
    // borderColor:'#a1a1a1',
    borderColor:'white',
    opacity:0.6,
    marginVertical:vh(0.5)
  },
  maskedBar:{
    justifyContent: 'center', 
    alignItems: 'center',
    backgroundColor:'yellow',
  },
  textBar:{
    width: '100%',
  },
  textBarContainer:{
    alignItems: 'flex-end',
    // backgroundColor:'red',
  },
  arrowIcon:{
    marginRight: vh(3),
  },
  arrowDown:{
    transform:[{ rotate: '180deg' }],
    marginRight: vh(2),
  }
})
