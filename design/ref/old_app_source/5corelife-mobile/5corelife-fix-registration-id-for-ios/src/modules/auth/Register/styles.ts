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
    alignSelf: 'center'
  },

  containerInputs: {
    width: vw(55),
    alignSelf: 'center',
    marginTop: vh(2.5)
  },

  containerInputUsername: {
    //
  },

  containerInputEmail: {
    marginTop: vh(1.25)
  },

  containerInputPassword: {
    marginTop: vh(1.25)
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
  },

  touchableOpacitySignIn: {
    flexDirection: 'row',
    alignSelf: 'center',
    alignItems: 'center',
    marginTop: vh(7.5),
    marginLeft: -vw(2.5)
  },

  imageSignIn: {
    width: vw(5),
    height: vw(5)
  },

  textSignIn: {
    paddingLeft: vw(2.5)
  },

  imageBackgroundScreen: {
    width: vw(95),
    height: vw(150)
  },

  viewTextScreen: {
    width: vw(70),
    height: vw(40),
    marginTop: vw(91.5),
    justifyContent: 'center',
    alignItems: 'center',
    alignSelf: 'center'
  },

  textScreen: {
    textAlign: 'center',
    textAlignVertical: 'center'
  },

  animatedViewScreen: {
    alignSelf: 'center',
    position: 'absolute',
    bottom: vh(125),
    zIndex:3
  },
})
