import { StyleSheet } from 'react-native'
import { Vintage, vintage } from 'react-native-color-matrix-image-filters'
import { vh, vw } from '../../../../helpers/dimensions'

export default StyleSheet.create({
  container: {
    flex: 1
  },

  containerSub: {
    flex: 1
  },

  /////////////////////////////////////
  /// CORES ///
  //////////////////////////////////////
  coresContainer:{
    // borderWidth:1,
    // borderColor:'pink',
    flex:3,
    alignItems: 'center',
  },

  modalCheckInOpacityContainerButton: {
    width: vw(25),
    height: vh(7),
    borderRadius: vw(10),
    borderWidth: vw(0.5),
  },
  modalCheckInTextDoneButton: {
    textShadowOffset: {
      width: 0.25,
      height: 1,
    },
    textShadowRadius: 5,
  },

  liquidMask:{
    height: "110%",
    width: "150%",
    position:'absolute',
    opacity:0.8
  },

  liquidMaskBottom:{
    height: "110%",
    width: "150%",
    position:'absolute',
    opacity:0.8
  },

  liquidMaskCentered:{
    height: "110%",
    width: "100%",
    position:'absolute',
    opacity:0.8,
  },

  imageMask:{
  },

  imageMaskContainer:{
    backgroundColor:'yellow',
    alignItems:'center',
    justifyContent:'center'
  },

  careerCorePosition: {
    // backgroundColor:'yellow',
    alignSelf: 'center',
    justifyContent: 'center',
    alignItems: 'center',
    position:'absolute',
    right:vh(3),
    bottom:vh(1),
  },

  imageSizeCentered:{
    height: vh(15), 
    width: vh(20), 
    justifyContent: 'center',
    alignItems: 'center',
  },

  imageSizeSides:{
    width: vh(13), 
    height: vh(20), 
    // backgroundColor:'green',
    justifyContent: 'center',
    alignItems: 'center',
  },

  imageSizeBottom:{
    width: vh(12.5), 
    height: vh(20), 
    justifyContent: 'center',
    alignItems: 'center',
  },

  imgAdjustCentered:{
    top:-vh(1)
  },

  imgAdjustSides:{
    top:-vh(1.5),
  },

  imgAdjustBottom:{
    // top:vh(1)
  },
  positionTouchableCenter:{
    height: vh(7.5),
    width:  vh(10),
    position:'absolute',
    top:vh(1.5),
    zIndex:9
  },
  positionTouchable:{
    height: vh(11),
    width:  vh(10),
    position:'absolute',
    zIndex:9
  },

  centerContent:{
    alignItems: 'center', 
    justifyContent: 'center'
  },

  visibleContainerZone:{
    borderColor:'white',
    borderWidth:1,
  },
  visibleTouchableZone:{
    borderWidth:2,
    borderColor:'red',
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
})
