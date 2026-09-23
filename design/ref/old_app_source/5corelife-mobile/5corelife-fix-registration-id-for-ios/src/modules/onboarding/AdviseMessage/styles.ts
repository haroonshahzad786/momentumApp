import { StyleSheet } from 'react-native'

import { vh, vw } from '../../../helpers/dimensions'

export default StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center'
  },

  imageButtonBack: {
    width: vw(10),
    height: vh(3)
  },

  animatedViewScreen: {
    alignSelf: 'center',
    position: 'absolute',
    top: -vh(100),
  },
  imageScreenBar: {
    height: '100%',
    alignSelf: 'center',
    // backgroundColor:'yellow',
  },
  imageBackgroundScreen: {
    width: vh(50),
    alignItems: 'center',
    justifyContent: 'center',
    //  backgroundColor:'red',
  },
  imageBackgroundScreenReverse: {
    // position: 'absolute',
    width: vw(80),
    height: vh(65),
    top: vh(90),
    // backgroundColor: 'red',
  },
  containerReverse: {
    backgroundColor: 'red',
  },
  contentScreen: {
    height: vh(28),
    width: '100%',
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 500,
    paddingHorizontal: vh(5),
    // backgroundColor:'green',
  },

  viewTextScreen: {
    width: vw(50),
    justifyContent: 'center',
  },

  textScreen: {
    textAlign: 'center',
    // backgroundColor:'blue'
  },

  invertColumns: {
    flexDirection: 'column-reverse'
  },

  marginSeparator: {
    marginTop: vh(1)
  },

  dotContainer: {
    position: 'absolute',
    bottom: -vh(1),
    // backgroundColor:'blue',
  },

  widthStress: {
    width: '80%'
  },
})
