import { StyleSheet } from 'react-native'

import { vh, vw } from '../../../helpers/dimensions'

export default StyleSheet.create({
  container: {
    flex: 1
  },

  containerSub: {
    flex: 1
  },

  containerImageLogo: {
    marginTop: -vh(7.5)
  },

  imageLogo: {
    width: vw(100),
    height: vh(75)
  },

  containerElements: {
    marginTop: -vh(20)
  },

  containerTitleText: {
    alignSelf: 'center',
    paddingHorizontal: vw(20)
  },

  textTitle: {
    textAlign: 'center',
    lineHeight: vh(3.5)
  },

  containerSubtitleText: {
    alignSelf: 'center',
    marginTop: vh(1.5)
  },

  imageCheckmark: {
    width: vw(25),
    height: vh(15),
    alignSelf: 'center',
    marginTop: vh(3.5),
    marginLeft: vw(3.5)
  },

  containerButtonRegister: {
    width: vw(25),
    alignSelf: 'center',
    marginTop: vh(3)
  },

  buttonLogin: {
    textShadowOffset: {
      width: 0.25,
      height: 1
    },
    textShadowRadius: 5
  },

  containerButtonRegisterImageLine: {
    position: 'relative',
    top: -vh(3),
    left: -vw(25),
    zIndex: -1
  },

  imageLine: {
    width: vw(75)
  }
})
