import { StyleSheet } from 'react-native'

import { vh, vw } from '../../../helpers/dimensions'

export default StyleSheet.create({
  imageBackgroundContainer: {
    flex: 1,
  },

  safeAreaViewContainer: {
    flex:1,
    zIndex:1,
    //backgroundColor:'red'
  },

  buttonNextStepPosition: {
    alignSelf:'flex-end',
    marginRight:vh(1),
    marginTop:'auto'
  },

  pageContainer:{
   height: '100%',
   width:'100%',
   position:'absolute',
  },

  flatList: {
    height: vh(21),
  },
  fullHeight: { 
    height: '100%',
    opacity:0.2
  },
  fontSizeFat:{
    fontSize: vh(1.65),
  },
})
