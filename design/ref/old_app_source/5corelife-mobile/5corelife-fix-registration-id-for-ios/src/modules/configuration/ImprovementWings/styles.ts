import { StyleSheet } from 'react-native'
import { RFValue } from 'react-native-responsive-fontsize'

import { vh, vw } from '../../../helpers/dimensions'

export default StyleSheet.create({
  container: {
    flex: 1
  },

  containerSub: {
    flex: 1
  },

  containerButtonBack: {
    position: 'absolute',
    top: vh(5.5),
    left: vw(5),
    zIndex: 2
  },

  containerHeaderSettings: {
    marginTop: vh(5),
    // backgroundColor:'green',
  },

  containerCardQuest: {
    marginHorizontal: vw(7.5),
    marginTop: vh(1.5),
    paddingHorizontal: vw(15),
    paddingTop: vh(1.5),
    paddingBottom: vh(2.5),
    borderRadius: 40,
    borderWidth: 3,
    shadowColor: '#000000',
    shadowOffset: {
      width: 20,
      height: 20
    },
    shadowOpacity: 0.75,
    shadowRadius: 12.5,
    elevation: 5
  },

  containerCardQuestTextHeader: {
    marginBottom: vh(1.5)
  },

  textQuestHeader: {
    textAlign: 'center'
  },

  containerCardQuestImageLine: {
    marginBottom: vh(1.75)
  },

  imageCardQuestLine: {
    width: vw(60),
    alignSelf: 'center'
  },

  containerCardQuestTextTitle: {
    marginBottom: vh(0.75)
  },

  textQuestTitle: {
    textAlign: 'center'
  },

  containerCardQuestTextDescription: {
    //
  },

  textQuestDescription: {
    textAlign: 'center',
    lineHeight: RFValue(24)
  },

  containerBgImprovementsIcon: {
  },

  containerImprovements: {
    //  backgroundColor:'yellow',
    justifyContent: 'center',
    alignContent: 'center'
  },

  containerImageImprovementsIcon: {
    // backgroundColor:'green',
    height: vh(45),
    flexDirection: 'row',
    alignContent: 'center'
  },

  imageImprovementsIcon: {
    height: vh(43),
    width: vh(43),
    paddingTop: vh(5),
    overflow: 'hidden',
    justifyContent: 'center',
    alignItems: 'center'
  },

  imageRocket: {
    width: vh(30),
    height: vh(35),
    zIndex: 10
  },

  alignBgFooter: {
    // backgroundColor:'red',
    flexDirection: 'row',
    paddingHorizontal: vw(5),
    marginTop: vh(8),
    justifyContent: 'center',
    flexWrap: 'wrap',
    alignItems: 'flex-start',
    alignContent: 'flex-start',
    zIndex:-1
  },

  buttonsBox: {
    // backgroundColor: 'yellow',
    flexDirection: 'row',
    justifyContent: 'center',
    flexWrap: 'wrap',
    alignItems: 'flex-start',
    alignContent: 'flex-start',
    marginTop: -vh(9),
  },

  alignBgWindow: {
    justifyContent: 'center',
  },

  // bgShadowImprovementsIcon:{
  //   height: vh(62),
  //   width: vw(85),
  //   position:'absolute',
  //   backgroundColor:'blue',
  //   left:vw(30),
  //   top:vh(2),
  //   opacity:0.8,
  // },

  containerButtonNormal: {
    marginHorizontal: vw(5),
    marginTop: vh(1),
  },

  imageBtnGreen: {
    width: vh(25),
    height: vh(18),
    alignItems: 'center',
    justifyContent: 'center',
    // backgroundColor:'red'
  },

  touchableStyle: {
    position: 'absolute',
    bottom: -vh(5),
    width: vh(25),
    height: vh(18),
    alignItems: 'center',
    justifyContent: 'center',
    zIndex:20
  },

  fontButton: {
    marginBottom: vh(2)
  },


  styleCenterRocketActived: {
    marginTop: -vh(1),
    zIndex: 10,
  },
  styleCenterBaseRocketActived: {
    flex: 1
  },
  animatedViewScreen: {
    alignSelf: 'center',
    position: 'absolute',
    bottom: vh(125),
    zIndex: 3
  },

  imageBackgroundScreen: {
    width: vw(95),
    height: vw(150)
  },

  viewTextScreen: {
    width: vw(70),
    height: vw(40),
    marginTop: vw(85),
    justifyContent: 'center',
    alignItems: 'center',
    alignSelf: 'center'
  },

  textScreen: {
    textAlign: 'center',
    textAlignVertical: 'bottom',
    height: '65%'
  },

  descriptionBonusCore: {
    backgroundColor: 'rgba(0,0,0,0.4)',
    width: '34%',
    position: 'absolute',
    top: '75%',
    borderRadius: 10
  },

  titleBonusCore: {
    textAlign: 'center',
    color: 'white'
  },

  size: {
    width: vw(14), 
    height: vh(12), 
    position: 'absolute', 
    opacity: 0.2, 
    alignSelf: 'center',
  }
})
