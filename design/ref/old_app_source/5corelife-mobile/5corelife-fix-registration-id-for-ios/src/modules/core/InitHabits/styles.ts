import { StyleSheet } from 'react-native'

import { vh, vw } from '../../../helpers/dimensions'

export default StyleSheet.create({
  imageBackgroundContainer: {
    flex: 1,
  },

  viewButtonBack: {
    position: 'absolute',
    top: vh(5.5),
    left: vw(5),
    zIndex: 2
  },

  viewCockpitScreen: {
    position: 'absolute',
    top: vh(0),
    right: vw(5),
  },

  touchableOpacityButtonPower: {
    position: 'absolute',
    alignSelf: 'center',
    bottom: vh(0),
  },

  imageButtonPower: {
    width: vw(25),
    height: vw(25),
  },

  viewElements: {
    position: 'absolute',
    alignSelf: 'center',
    top: vh(52.5),
    paddingHorizontal: vw(15),
  },

  textTitle: {
    marginBottom: vh(1),
    textAlign: 'center',
    shadowOffset: {
      width: 2.5,
      height: 5,
    },
    shadowOpacity: 1,
    shadowRadius: 5,
  },

  imageLine: {
    width: vw(40),
    alignSelf: 'center',
    marginBottom: vh(1),
  },

  textSubtitle: {
    textAlign: 'center',
  },

  modalQuizTextDoneButton: {
    textShadowOffset: {
      width: 0.25,
      height: 1,
    },
    textShadowRadius: 5,
  },

  containerHeaderSettings: {
    zIndex: 1
  },

  animatedViewScreen: {
    alignSelf: 'center',
    position: 'absolute',
    bottom: vh(125),
    zIndex: 2
  },

  imageBackgroundScreen: {
    width: vw(95),
    height: vw(150)
  },

  viewTextScreen: {
    width: vw(70),
    height: vw(40),
    marginTop: vw(92),
    justifyContent: 'center',
    alignItems: 'center',
    alignSelf: 'center'
  },

  textScreen: {
    textAlign: 'center',
    textAlignVertical: 'center',
  },

})
