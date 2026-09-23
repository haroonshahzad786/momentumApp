import { StyleSheet } from 'react-native'

import { vh, vw } from '../../../helpers/dimensions'

export default StyleSheet.create({
  container: {
    flex: 1,
  },

  containerSub: {
    flex: 1,
  },

  containerTWF: {
    flex: 1,
    backgroundColor:'black'
  },

  containerImageBackground: {
    height: '100%',
    width: '100%',
  },

  columnContainer: {
    alignItems: 'center',
    justifyContent: 'space-between',
    //backgroundColor:'white',
    height: '100%',
  },

  imageDestination: {
    height: vh(20),
    width: vh(20),
    //backgroundColor:'purple',
  },

  imageRocket: {
    position: 'absolute',
    height: vh(15),
    width: vh(10),
    alignItems:'center',
    justifyContent:'center'
    //backgroundColor:'yellow',
  },

  imageOrigin: {
    // backgroundColor:'red',
    height: vh(20),
    width: vh(20),
    marginBottom: vh(5)
  },

  flyingObstacule: {
    height: vh(15),
    width: vh(20),
    // backgroundColor:'green',
    marginTop: -vh(25),
  },

  flexItem: {
  },

  lineCentered: {
    backgroundColor: 'red',
    position: 'absolute',
    height: '80%',
    marginTop: '10%',
  },

  lineaGuia: {
    position: 'absolute',
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
  }
})
