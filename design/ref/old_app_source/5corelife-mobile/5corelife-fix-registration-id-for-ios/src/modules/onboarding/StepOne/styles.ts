import { StyleSheet } from 'react-native'

import { vh, vw } from '../../../helpers/dimensions'

export default StyleSheet.create({
  imageBackgroundContainer: {
    flex: 1,
  },

  safeAreaViewContainer: {
    flex:1,
  },

  buttonNextStepPosition: {
    alignSelf:'flex-end',
    marginRight:vh(2),
    marginTop:'auto',
  },

  imagePlanet:{
    height:vh(35),
    position:'absolute',
    bottom:vh(25),
    width:'100%'
  },

  fontSizeFat: {
    fontSize: vh(1.85),
  }
})
