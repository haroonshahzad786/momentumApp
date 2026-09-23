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
    marginTop: -vh(15),
    display: 'flex',
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center'
  },

  imageLogo: {
    // width: vh(90),
    height: vh(48),
    position: 'absolute',
    zIndex: 1,
  },

  containerElements: {
    marginTop: -vh(15)
  },

  containerTextSignIn: {
    alignSelf: 'center',
  },

  containerInputs: {
    width: vw(55),
    alignSelf: 'center',
    marginTop: vh(2.5)
  },

  containerInputUsername: {
    //
  },

  containerInputPassword: {
    marginTop: vh(1.25)
  },

  containerButtonLogin: {
    width: vw(25),
    alignSelf: 'center',
    marginTop: vh(3)
  },

  buttonLogin: {
    textShadowOffset: {
      width: 0.25,
      height: 1
    },
    textShadowRadius: 5,
  },

  containerButtonLoginImageLine: {
    position: 'relative',
    top: -vh(3),
    left: -vw(25),
    zIndex: -1
  },

  imageLine: {
    width: vw(75)
  },

  containerTextConnectWith: {
    alignSelf: 'center',
    marginTop: vh(3.75),
    borderRadius: 50,
    width: vw(35),
    position: 'relative',
    zIndex: 2
  },

  containerBackgroundConnectWith: {
    width: vw(65),
    paddingTop: 10,
    alignSelf: 'center',
    marginTop: vh(.7),
    borderRadius: 50,
    position: 'relative',
    bottom: vh(2),
    zIndex: 1
  },

  containerSocial: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    alignItems: 'center',
    height: vh(9),
    paddingHorizontal: vw(2)
  },

  containerImageSocial: {
    alignItems: 'center'
  },

  imageSocial: {
    width: vw(12.5)
  },

  containerTextRegister: {
    alignSelf: 'center',
    marginTop: vh(2)
  },

  containerTextForgotPassword: {
    alignSelf: 'center',
    marginTop: vh(1.25)
  },

  backgroundConnect: {
    padding: vh(.7),
    textAlign: 'center',
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
    textAlignVertical: 'center'
  },

  textScreenHighlight: {
    top: vh(2),
    fontWeight: 'bold'
  },

  imageBackground: {
    height: vh(70),
    // backgroundColor:'red'
    marginLeft: vw(1.5),
    marginTop: vh(5)
  },

  liquidMask: {
    backgroundColor: 'black',
    bottom: "10%",
  },

  imageSize: {
  },

  textLoading: {
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: vh(10)
  },

  imageSizeLoaderContainer: {
    width: vh(5),
    height: vh(30),
    backgroundColor: 'black',
  },

  loadingBarContainer: {
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: vh(2),
  },

  loadingBar: {
    width: vh(3),
    height: vh(20),
    backgroundColor: 'black',
  },

  barVertical: {
    width: vh(3),
    height: vh(20),
    alignSelf: 'center',
    backgroundColor: 'black',
    borderRadius: 50,
    borderWidth: vh(0.3),
    borderColor: '#11315a',
  },

  percentageLoaded: {
    color: '#ec7e3f',
    textShadowOffset: {
      width: 1,
      height: 1,
    },
    textShadowRadius: 5,
  },

  viewRocket: {
    position: 'absolute',
    alignSelf: 'center',
    top: vh(35),
    width: "100%"
  },

  waterAnimation: {
    height: '100%',
    width: '100%'
  },

  containerImageFooter: {
    // backgroundColor: 'yellow',
    marginTop: vh(1),
    alignItems: 'center',
    width: '100%'
  },
  imageFooter: {
    marginTop: vh(8),
    width: vw(44),
    height: vh(3)
  }
})
