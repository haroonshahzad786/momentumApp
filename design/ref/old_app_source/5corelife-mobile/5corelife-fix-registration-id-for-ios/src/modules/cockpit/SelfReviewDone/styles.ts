import { StyleSheet } from 'react-native'
import { RFValue } from 'react-native-responsive-fontsize'

import { vh, vw } from '../../../helpers/dimensions'

export default StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#000000'
  },

  containerImageBackgroundCockpit: {
    width: vw(120),
    height: vh(100),
    marginLeft: -vw(10)
  },

  containerCockpitScreen: {
    position: 'absolute',
    top: -vh(1.75),
    right: vw(12.5)
  },

  containerElements: {
    position: 'absolute',
    width: vw(40),
    alignSelf: 'center',
    top: vh(45)
  },

  containerImageWellDone: {
    alignSelf: 'center'
  },

  imageWellDone: {
    //
  },

  containerTextTitle: {
    marginVertical: vh(2.5)
  },

  textTitle: {
    textAlign: 'center'
  },

  containerSeparator: {
    width: vw(20),
    height: 0.3,
    alignSelf: 'center',
    opacity: 0.3
  },

  containerTextSubtitle: {
    marginTop: vh(2.5)
  },

  textSubtitle: {
    textAlign: 'center',
    lineHeight: RFValue(25)
  },

  containerButtonDone: {
    position: 'absolute',
    alignSelf: 'center',
    width: vw(22.5),
    bottom: vh(9.5)
  },

  buttonDone: {
    textShadowOffset: {
      width: 0.25,
      height: 1
    },
    textShadowRadius: 5
  }
})
