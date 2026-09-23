import { StyleSheet } from 'react-native'

import { vh, vw } from '../../helpers/dimensions'

export default StyleSheet.create({
  imageBackgroundContainer: {
    width: vw(107.5),
    height: vh(100),
    alignSelf: 'center',
    marginTop: -vh(5)
  },

  textTitle: {
    alignSelf: 'center',
    marginTop: vh(36.5)
  },

  touchableOpacityImageIconRight: {
    alignSelf: 'center',
    marginTop: vh(3.5),
    marginLeft: vw(75)
  },

  viewTextInput: {
    alignSelf: 'center',
    marginTop: vh(5),
    paddingHorizontal: vw(10),
    width: '100%',
  },

  textInput: {
   width: '100%',
  },

  viewSwitch: {
    /*flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: vh(4),*/
    flexDirection: 'row',
    position: 'absolute',
    alignSelf: 'center',
    right: vw(32),
    bottom: vh(36.5)
  },

  textSwitch: {
    marginBottom: -vh(0.5),
    paddingHorizontal: vw(2.5)
  },

  touchableOpacityButton: {
    position: 'absolute',
    alignSelf: 'center',
    right: vw(16),
    bottom: vh(14)
  }
})
