import { StyleSheet } from 'react-native'

import { vh, vw } from '../../../helpers/dimensions'

export default StyleSheet.create({
  container: {
    flex: 1,
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
    //backgroundColor: 'yellow',
    marginTop: vh(6),
    flexBasis: "10%",
  },

  // BONUS Section
  containerBonus: {
    //backgroundColor: '#ff00ffAA',
    flexBasis: "50%",
    alignItems: 'center',
    justifyContent: 'center'
  },

  bonusBkgdMainContainer: {
    //backgroundColor: '#c5c5c5AA',
    width: vh(48),
    height: vh(48),
    alignItems: 'center',
    justifyContent: 'center',
  },
  bonusBkgdContainer: {
    //backgroundColor: '#90f022AA',
    width: vh(40),
    height: vh(40),
    justifyContent: 'flex-end',
    alignItems: 'center'
  },
  buttonActivateContainer: {
    //backgroundColor: '#ff0000AA',
    width: vw(30),
  },

  // DAYS Section
  containerDays: {
    //backgroundColor: 'red',
    display: 'flex',
    flexBasis: "30%",
    flexDirection: 'row',
    alignItems: 'center',

  },
  containerDay: {
    //backgroundColor: 'blue',
    flex: 1,
    alignItems: 'center',
  },

  buttonsContainer: {
    //backgroundColor: 'yellow',
    height: vh(14),
  },

  buttonContainer: {
    //backgroundColor: 'red',
    width: 61,//vw(20),
    height: 61,//vh(10),
    alignItems: 'center',
  },
  buttonContainerImage: {
    marginTop: 17,
  },

  buttonContainerImageScore: {
    alignSelf: 'center',
    marginTop: -6,
  },

  containerDayImageText: {

  },

  contScoreText: {
    paddingHorizontal: 15,
    paddingVertical: 10
  },

  textDoneButton: {
    textShadowOffset: {
      width: 0.25,
      height: 1,
    },
    textShadowRadius: 5,
  },

  containerButtonHeader: {
    marginTop: -vh(9),
    marginHorizontal: vw(1)
  },

  containerButtonNormal: {
    marginHorizontal: vw(5)
  },

  containerImageImprovementsIcon: {
    // backgroundColor:'green',
    height: vh(45),
    flexDirection: 'row',
    alignContent: 'center'
  },


  alignBgFooter: {
    //backgroundColor:'red',
    flexDirection: 'row',
    paddingHorizontal: vw(5),
    marginTop: vh(12),
    justifyContent: 'center',
    flexWrap: 'wrap',
    alignItems: 'flex-start',
    alignContent: 'flex-start'
  },

  alignBgWindow: {
    justifyContent: 'center',
  },

  bonusDescription: {
    marginTop: vh(4),
    textAlign: 'center',
    textShadowOffset: {
      width: 1,
      height: vh(0.5)
    },
    textShadowRadius: vh(.5),
  },
  styleCenterRocketActived: {
    marginTop: vh(2),
    width: vh(6),
    height: vh(6),
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
    height: '55%'
  },

  buttons: {
    width: vw(10),
    height: vh(6)
  }
})
