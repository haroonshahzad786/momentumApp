import { StyleSheet } from 'react-native'

import { vh, vw } from '../../../helpers/dimensions'

export default StyleSheet.create({
  imageBackgroundContainer: {
    flex: 1,
    zIndex: 20
  },

  safeAreaViewContainer: {
    //
    zIndex: 21
  },

  animatedViewScreen: {
    alignSelf: 'center',
    position: 'absolute',
    top: -vh(110)
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
    textAlignVertical: 'center'
  },

  textScreenHighlight: {
    top: vh(2)
  },

  touchableOpacityButtonNext: {
    alignSelf: 'center',
    position: 'absolute',
    right: vw(7.5),
    bottom: -vh(100)
  },

  imageButtonNext: {
    width: vw(15)
  },
  pageContainer: {
    height: '100%',
    width: '100%',
    zIndex: 22,
  },
})
