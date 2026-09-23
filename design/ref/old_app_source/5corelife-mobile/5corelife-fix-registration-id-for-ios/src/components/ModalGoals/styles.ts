import { StyleSheet } from 'react-native'

import { vh, vw } from '../../helpers/dimensions'

export default StyleSheet.create({
  imageBackgroundContainer: {
    width: vw(87.5),
    height: vh(80),
    alignSelf: 'center',
    marginTop: -vh(20)
  },

  textTitle: {
    alignSelf: 'center',
    textAlign: 'center',
    marginTop: vh(28.4),
    marginHorizontal: vw(12),
    fontSize: vw(5)
  },

  textDescription: {
    alignSelf: 'center',
    textAlign: 'center',
    marginTop: vh(4),
    marginHorizontal: vw(12),
    fontSize: vw(4)
  },

  touchableOpacityButton: {
    position: 'absolute',
    alignSelf: 'center',
    right: vw(12.5),
    bottom: vh(10)
  }

  /*
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
    // flexDirection: 'row',
    // alignItems: 'center',
    // justifyContent: 'center',
    // marginTop: vh(4),
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

 
  */
})
