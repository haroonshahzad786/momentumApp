import { StyleSheet } from 'react-native'
import { toBGR, Vintage } from 'react-native-color-matrix-image-filters'

import { vh, vw } from '../../../helpers/dimensions'

export default StyleSheet.create({
  imageBackgroundContainer: {
    flex: 1,
  },

  containerButtonBack: {
    position: 'absolute',
    top: vh(3),
    left: vw(5),
    zIndex:2
  },
  containerButtonNext: {
    top:vh(3),
    left: vw(5),
    position: 'absolute',
    transform:[{ rotate: '180deg' }]
  },
  containerHeaderSettings: {
    marginTop: vh(6),
    marginBottom:vh(2)
  },
  containerTrophiesSection:{
    justifyContent:'center',
    alignItems:'center',
    // backgroundColor:'green',
  },
  imageTrophyContainer:{
    width: vh(45),
    height: vh(45),
    overflow:'hidden'
  },

  imageTrophy: {
    width: vh(32),
    height: vh(32),
    alignSelf: 'center',
    top: vh(4.5),
    marginLeft:vw(1)
  },

  imageCongratulations: {
    width: vh(30),
    height: vh(25),
    position: 'absolute',
    alignSelf: 'center',
    top: vh(28),
    zIndex:2,
    // backgroundColor:'red'
  },
  imageViewInfoContainer:{
    position:'absolute',
    opacity:0.5,
  },
  viewInfo: {
    width: vw(75),
    height:vh(26),
    // height: vw(50),
    borderBottomLeftRadius:50,
    borderBottomEndRadius:50,
    position: 'relative',
    alignSelf: 'center',
    marginTop:vh(2),
    alignItems:'center',
    alignContent:'center',
    justifyContent:'center'

  },
  descriptionTrophyContainer:{
    marginVertical:vh(3),
    alignItems: 'center', 
    justifyContent: 'center', 
    // backgroundColor: 'red'
  },
  dividerLine:{
    position:'absolute',
    top:-10,
    height:3,
    width: vw(75),
  },
  textTitle: {
    marginHorizontal: vh(1.5),
    textAlign: 'center',
    textShadowOffset: {
      width:0,
      height: vh(0.5)
    },
    textShadowRadius: vh(1),
  },

  imageLine: {
    width: vw(65.5),
    marginVertical:vh(2)
  },

  textSubtitle: {
    textAlign: 'center',
    textShadowOffset: {
      width:0,
      height: vh(0.5)
    },
    textShadowRadius: vh(2),
  },
  buttonZoneSwypeTrophies:{
    // backgroundColor:'red',
    position: 'absolute',
    flexDirection:'row',
    justifyContent:'space-between',
    width: vh(45),
    top:vh(20),
    paddingHorizontal:vw(8),
  },
  buttonSwypeLeft:{
    transform:[{ rotate: '180deg' }]
  },
  buttonSwypeRight:{
  },
  scrollDescriptionContainer:{
    overflow: 'hidden',
    paddingHorizontal:  vw(6),
    alignSelf:'center',
    // backgroundColor:'red',
  },

  locked:{
    opacity:0.5,
    alignItems:'center',
    justifyContent:'center',
  },

})
