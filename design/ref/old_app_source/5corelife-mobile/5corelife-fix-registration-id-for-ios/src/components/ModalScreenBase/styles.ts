import { StyleSheet } from 'react-native'

import { vh, vw } from '../../helpers/dimensions'

export default StyleSheet.create({
  imageBackgroundContainer: {
    width: vw(100),
    height: vh(95),
    alignSelf: 'center',
    marginTop: -vh(10),
    marginLeft: vw(2),
  },
  imageMask: {
    width: '100%',
    height: '100%',
    position: 'absolute',
  },
  imageBackground: { width: '100%', height: '100%' },
  buttonDone: {
    alignSelf: 'center',
    zIndex:12
  },
  mainContainer: {
    alignItems: 'stretch',
    alignSelf: 'center',
    marginTop: vh(18),
    marginLeft: -vh(1.2),
    // height: vh(75),
    width: vw(80),
    // backgroundColor: '#ff0000AA',
  },
  okButtonContainer: {
    width: vw(30),
    height: vh(10),
    bottom: vh(1),
    left: vw(30),
    position: 'absolute',
    justifyContent: 'center',
    alignItems: 'center',
  },
  containerButtonBack: {
    position: 'absolute',
    top: vh(10),
    left: vw(1),
    zIndex: 9,
  },
})
