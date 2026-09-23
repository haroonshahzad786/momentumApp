import { StyleSheet } from 'react-native'
import { RFValue } from 'react-native-responsive-fontsize'

import { vh, vw } from '../../../helpers/dimensions'

export default StyleSheet.create({
  imageBackgroundContainer: {
    flex: 1
  },

  viewButtonBack: {
    position: 'absolute',
    top: vh(5.5),
    left: vw(5),
    zIndex:2,
  },

  viewCockpitScreen: {
    position: 'absolute',
    top: vh(0),
    right: vw(5)
  },

  touchableOpacityButtonPower: {
    position: 'absolute',
    alignSelf: 'center',
    bottom: vh(0)
  },

  imageButtonPower: {
    width: vw(25),
    height: vw(25)
  },

  viewElements: {
    position: 'absolute',
    alignSelf: 'center',
    top: vh(40)
  },

  textOr: {
    marginVertical: vh(2),
    textAlign: 'center'
  },

  viewButton: {
    //
  },

  viewScoreProgress: {
    position: 'absolute',
    alignSelf: 'center',
    bottom: vh(15)
  },

  textInputModal: {
    fontSize: RFValue(32)
  },

  imageButtonModal: {
    width: vw(17.5),
    height: vw(17.5)
  },

  containerHeaderSettings:{
    
  }
})
