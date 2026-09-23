import { StyleSheet } from 'react-native'

import { vh, vw } from '../../../helpers/dimensions'

export default StyleSheet.create({
  imageBackgroundContainer: {
    flex: 1,
  },

  safeAreaViewContainer: {
    flex:1,
    zIndex:1,
    // backgroundColor:'red'
  },

  buttonNextStepPosition: {
    alignSelf:'flex-end',
    marginRight:vh(2),
    marginTop:vh(80),
    zIndex:2,
  },

  imagePlanet:{
    height:vh(35),
    position:'absolute',
    bottom:vh(25),
    width:'100%'
  },

  pageContainer:{
    height: '100%',
    width:'100%',
    zIndex:0,
   },

   absolute:{
    position:'absolute',     
   },
 ///////////////////////
  // ONBOARDING STYLES.
  ///////////////////////
  
  darkVeil:{
    backgroundColor: 'rgba(0,0,0,0.6)'
  },
  lowOpacity:{
    opacity:0.5
  },
  arrowIndicatorPosition:{
    marginBottom:vh(3.5),
  },
  maskedView:{

  },
  fullHeight:{
    height:'100%'
  },
  fontSize: {
    fontSize: vh(1.6)
  }
})
