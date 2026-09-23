import { StyleSheet } from 'react-native'

import { vh, vw } from '../../../helpers/dimensions'

export default StyleSheet.create({
  viewContainer: {
    flex: 1,
    justifyContent: 'center',
  },

  /*indicatorCockpit: {
    width: vh(11),
    top: '-13.5%',
    backgroundColor: 'black',
    zIndex: -1,
  },*/

  imageBackgroundPointsScreen: {
    position: 'absolute',
    width: vw(47.5),
    height: vh(27.5),
    top: vh(0),
    right: -vw(5),
  },

  imageBackgroundPointsScreen2: {
    position: 'absolute',
    width: vw(33),
    height: vh(24),
    top: vh(0),
    right: -vw(5),
    zIndex: 2,
    borderRadius: 40
  },

  viewCoins: {
    width: vw(20),
    height: vh(3.5),
    overflow: 'hidden',
    flexDirection: 'row',
    alignSelf: 'center',
    marginTop: vh(7.5),
    justifyContent: 'space-evenly',
  },

  viewCoinsImage: {
    // paddingRight: vw(6),
  },

  imageCoins: {
    width: vw(5.5),
    height: vh(3),
  },

  viewCoinsText: {
    width: '55%',
    //
  },

  viewPlanet: {
    width: vw(20),
    overflow: 'hidden',
    flexDirection: 'row',
    alignSelf: 'center',
    // justifyContent: 'center',
    marginTop: vh(0.5),
    justifyContent: 'space-evenly'
  },

  viewPlanetImage: {
    // paddingRight: vw(0.75),
  },

  imagePlanet: {
    width: vw(7),
    height: vh(3),
  },

  viewPlanetText: {
    marginTop: vh(0.35),
  },

  viewMomentumScoreTitleText: {
    width: vw(25),
    alignSelf: 'center',
    marginTop: vh(1.5),
  },

  textMomentumScoreTitle: {
    textAlign: 'center',
    textShadowOffset: {
      width: 0.5,
      height: 1,
    },
    textShadowRadius: 5,
  },

  viewMomentumScore: {
    flexDirection: 'row',
    alignSelf: 'center',
    marginTop: vh(0.25),
  },

  viewMomentumScorePercentageText: {
    marginTop: vh(0.5),
    paddingRight: vw(1),
  },

  textMomentumScorePercentage: {
    textAlign: 'center',
    textShadowOffset: {
      width: 0.5,
      height: 1,
    },
    textShadowRadius: 5,
  },

  viewMomentumScoreAmountText: {
    //
  },

  textMomentumScoreAmount: {
    width: '90%',
    textAlign: 'center',
    textShadowOffset: {
      width: 0.5,
      height: 1,
    },
    textShadowRadius: 5,
    marginTop: vh(.4),
  },

  containerMomentumScore: {
    alignSelf: 'center',
    justifyContent: 'center',
    width: '40%',
  },

  textMomentumScore: {
    marginTop: vh(.9),
    textAlign: 'center',
    fontSize: vw(2.2),
  },

  textMomentumScoreTotal: {
    marginTop: vh(.4),
    textAlign: 'center',
    fontSize: vh(2),
  },

  viewWingsImage: {
    //
  },

  imageWings: {
    position: 'absolute',
    top: vh(20),
    width: vh(50),
    //backgroundColor:'green'
  },

  imageWingsContainer: {
    width: vh(70),
    top: vh(29),
  },
  imageWing: {
    position: 'absolute',
    width: vh(40),
    height: vh(45),
    //backgroundColor:'red',
  },

  imageWingRight: {
    alignSelf: 'flex-end',
    transform: [{ scaleX: -1 }] //Mirror effect
  },
  imageWingLeft: {
    alignSelf: 'flex-start',
  },

  viewFlameImage: {
    //
  },
  rocketContainer: {
    height: vh(70),
    alignItems: 'center',
    justifyContent: 'center',
    // backgroundColor:'white',
  },
  imageFlame: {
    position: 'absolute',
    width: '100%',
    height: vh(30),
    top: vh(58),
    // backgroundColor:'yellow'
  },
  imageFlameCentered: {
    position: 'absolute',
    width: vh(18),
    height: vh(45),
    top: vh(53),
    zIndex: -1
    // backgroundColor:'yellow'
  },
  imageFlameDuoCentered: {
    // backgroundColor:'red',
    position: 'absolute',
    flexDirection: 'row',
    height: vh(20),
    top: vh(61),
    left: vw(8),
    width: '80%',
    alignItems: 'center',
    justifyContent: 'center',
    zIndex: -2
  },
  imageFlameDobleCentered: {
    position: 'absolute',
    flexDirection: 'row',
    height: vh(20),
    top: vh(64.2),
    left: vw(8),
    width: '80%',
    alignItems: 'center',
    justifyContent: 'center',
    zIndex: 9
  },
  imageFlameDuothird: {
    // backgroundColor:'red',
    position: 'absolute',
    flexDirection: 'row',
    height: vh(20),
    top: vh(62),
    left: vw(5.7),
    width: '80%',
    alignItems: 'center',
    justifyContent: 'center',
    zIndex: -2
  },
  flameLeftCentered: {
    width: vh(13),
  },
  flameRightCentered: {
    width: vh(13),
  },
  imageFlameDuo: {
    // backgroundColor:'red',
    position: 'absolute',
    flexDirection: 'row',
    height: vh(20),
    top: vh(63),
    width: '80%',
    alignItems: 'center',
    justifyContent: 'center',
    zIndex: -1
  },

  flameLeft: {
    width: vh(10),
  },

  flameRight: {
    width: vh(10),
  },

  imageFlameAnimation: {
    zIndex: -1,
  },

  imageFlameDuoExtended: {
    position: 'absolute',
    flexDirection: 'row',
    height: vh(20),
    top: vh(57),
    width: vh(33),
    alignItems: 'center',
    justifyContent: 'space-between',
    zIndex: -3,
    // backgroundColor:'red'
  },

  flameLeftExtended: {
    width: vh(12),
    // backgroundColor:'yellow'
  },

  flameRightExtended: {
    width: vh(12),
    // backgroundColor:'yellow'
  },


  viewRocket: {
    position: 'absolute',
    alignSelf: 'center',
    top: vh(35),
    width: "100%"
  },

  imageBackgroundRocket: {
    // backgroundColor:'blue',
    zIndex: 3,
    width: vw(65),
    height: vh(65),
    alignSelf: 'center',
    justifyContent: 'center',
  },

  safeAreaViewRocket: {
    // borderWidth:1,
    // borderColor:'black',
    height: vh(55),
    width: vh(30),
    alignSelf: 'center',
  },


  handleContainer: {
    // borderWidth:1,
    // borderColor:'white',
    justifyContent: 'center',
    alignItems: 'center',
    height: vh(12),
  },


  touchableOpacityHandleImage: {
    // backgroundColor:'green',
    alignSelf: 'center',
    justifyContent: 'center',
    alignItems: 'center',
    zIndex: 2
  },

  imageHandle: {
    marginTop: vh(2.5),
    width: vh(6),
    height: vh(4),
  },

  handleContainerInferior: {
    // backgroundColor:'white',
    flexDirection: "row",
    justifyContent: 'space-between',
    width: vh(13.5),
    paddingVertical: vh(1),
  },

  touchableOpacityStorageImage: {
  },

  imageStorage: {
    // backgroundColor:'blue'
    width: vh(4),
    height: vh(4),
  },

  touchableOpacitySettingsImage: {
  },

  imageSettings: {
    // backgroundColor:'blue'
    width: vh(4),
    height: vh(4),
    zIndex: 2
  },


  /////////////////////////////////////
  /// CORES ///
  //////////////////////////////////////
  coresContainer: {
    // borderWidth:1,
    // borderColor:'pink',
    flex: 3,
    alignItems: 'center',
  },

  placementCoreMindsetImage: {
    alignItems: 'center',
    marginTop: vh(1.5),
    zIndex: 10
  },

  placementCoreEmotionalImage: {
    justifyContent: 'center',
    alignItems: 'center',
    position: 'absolute',
    marginTop: vh(7),
    left: vh(2),
    transform: [{ rotate: '2deg' }]
  },

  placementCoreRelationshipImage: {
    justifyContent: 'center',
    alignItems: 'center',
    position: 'absolute',
    marginTop: vh(7),
    right: vh(2),
    transform: [{ rotate: '-2deg' }]
  },


  placementCorePhysicalImage: {
    justifyContent: 'center',
    alignItems: 'center',
    position: 'absolute',
    left: vh(3),
    bottom: vh(1),
  },

  placementCoreCareerImage: {
    justifyContent: 'center',
    alignItems: 'center',
    position: 'absolute',
    right: vh(3),
    bottom: vh(1),
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

  backgroundVideo: {
    position: "absolute",
    top: 0,
    left: 0,
    alignItems: "stretch",
    bottom: 0,
    right: 0
  },

  turbines: {
    // backgroundColor:'red',
    zIndex: 2,
    position: 'absolute',
    width: '100%',
    height: '100%',
    top: vh(6.5),
    alignItems: 'center',
    justifyContent: 'center'
  },
  ///////////////////////
  // ONBOARDING STYLES.
  ///////////////////////

  darkVeil: {
    backgroundColor: 'rgba(0,0,0,0.6)'
  },
  lowOpacity: {
    opacity: 0.5
  },
  arrowIndicatorPosition: {
    marginTop: vh(8),
    position: 'absolute',
    zIndex: 9,
  },
  arrowIndicatorCockpitPosition: {
    // marginTop: -vh(4),
    position: 'absolute',
    top: '-6%',
    right: '23%',
    justifyContent: 'flex-start',
    zIndex: 1,
  },
  highlightStyle: {
    zIndex: 1,
    width: vw(21),
    top: '-26%',
    right: '16%',
  },
  arrowIndicatorCockpitPositionSetting: {
    // marginTop: -vh(4),
    position: 'absolute',
    top: '-39%',
    right: '-40%',
    justifyContent: 'flex-start',
    zIndex: 1,
  },
  highlightStyleSetting: {
    zIndex: 1,
    width: vw(15),
    top: '-26%',
    right: '36%',
  },
  flamaCohete: {
    zIndex: -1,
    position: 'absolute',
    bottom: '-20.6%',
    width: 150,
    height: vh(28),
  },
  newFlamaCohete: {
    zIndex: -1,
    position: 'absolute',
    bottom: '-20.6%',
    width: vh(20.5),
    height: vh(35.5),
  },
  flamaLeft: {
    zIndex: -2,
    position: 'absolute',
    left: '22.8%',
    bottom: '-9%',
    width: vw(27),
    height: vh(30),
    transform: [
      {
        rotate: '8deg'
      }
    ]
  },
  flamaCenter: {
    zIndex: -1,
    position: 'absolute',
    left: '39%',
    bottom: '-25%',
    width: vw(27),
    height: vh(30),
  },
  flamaRight: {
    zIndex: -2,
    position: 'absolute',
    left: '54%',
    bottom: '-9.2%',
    width: vw(27),
    height: vh(30),
    transform: [
      {
        rotate: '350deg'
      }
    ]
  },
  containerFlamaLast: {
    zIndex: 2,
    position: 'absolute',
    width: '100%',
    height: '100%',
    top: -vh(11),
  },
  flamaLastLeft: {
    width: vw(27),
    position: 'absolute',
    right: '55%',
    height: vh(30),
    transform: [{ rotate: '17deg' }]
  },
  flamaLastRight: {
    width: vw(27),
    position: 'absolute',
    right: '6.3%',
    height: vh(30),
    transform: [{ rotate: '340deg' }]
  },
  flamaLeftLast: {
    width: vw(17),
    position: 'absolute',
    right: '47%',
    height: vh(30),
  },
  flamaRightLast: {
    width: vw(17),
    position: 'absolute',
    right: '26%',
    height: vh(30),
  },
  flamaCenterMiddle: {
    zIndex: 3,
    position: 'absolute',
    left: '27.3%',
    bottom: '-85%',
    width: vw(40),
    height: vh(50),
  },
  containerFlamaFive: {
    zIndex: 3,
    position: 'absolute',
    width: '100%',
    height: '100%',
    top: -vh(8.8),
  },
  flamaLeftMiddle: {
    width: vw(27),
    position: 'absolute',
    right: '50%',
    height: vh(30),
    transform: [{ rotate: '17deg' }],
  },
  flamaRightMiddle: {
    width: vw(27),
    position: 'absolute',
    right: '11.5%',
    height: vh(30),
    transform: [{ rotate: '340deg' }]
  },
  modalQuizTextDoneButton: {
    textShadowOffset: {
      width: 0.25,
      height: 1,
    },
    textShadowRadius: 5,
  },
  modalQuestOpacityContainerButton: {
    width: vw(25),
    height: vh(7),
    borderRadius: vw(10),
    borderWidth: vw(0.5),
  },
  modalQuestTextDoneButton: {
    textShadowOffset: {
      width: 0.25,
      height: 1,
    },
    textShadowRadius: 5,
  },


  okBtn: {
    width: vw(20),
    height: vw(23),
    // width: vw(30),
    // THIS WAS NOT --> height: vw(25),
    marginTop: vh(10),
    marginLeft: vh(2)
    // top: '50%'
  },
  alien1: {
    marginTop: vh(16.5),
    height: vw(140),
  },
  activityIndicator: {
    // flex
  },
  imageButtonModal: {
    width: vw(13.5),
    height: vw(13.5)
  },
})
