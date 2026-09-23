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
  },
  mainContainer: {
    alignItems: 'stretch',
    alignSelf: 'center',
    marginTop: vh(18),
    marginLeft: -vh(1.2),
    // height: vh(75),
    width: vw(80),
    //backgroundColor: '#ff0000AA',
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

  containerBtn: {
    width: '70%',
    marginTop: -vh(14),
    marginLeft: vh(8),
justifyContent: 'space-between',
    flexDirection: 'row',

  },

  offsetContainerIcon: {
    // position: 'absolute',
    // marginLeft: "-5%",
    zIndex: 9
  },

  containerBubble: {
    width: vw(15),
    height: vw(15),
    overflow: 'hidden',
    shadowColor: '#000000',
    elevation: 5,
    justifyContent: 'center',
    alignItems: 'center',
    borderRadius: 500,
  },
  
  bubbleShape: {
    width: vw(15.5),
    height: vw(15.5),
    borderRadius: 500,
    overflow: 'hidden',
    justifyContent: 'center',
    alignItems: 'center',
    elevation: 5,
  },
})
