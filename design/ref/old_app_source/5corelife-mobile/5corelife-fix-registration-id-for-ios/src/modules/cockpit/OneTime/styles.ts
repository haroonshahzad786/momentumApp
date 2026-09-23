import { StyleSheet } from 'react-native'

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

  containerButtonBack: {
    position: 'absolute',
    top: vh(4),
    left: vw(17.5),
    zIndex: 9
  },

  containerCockpitScreen: {
    alignSelf: 'center',
    position: 'absolute',
    top: -vh(30)
  },

  textInspiration: {
    lineHeight: vh(3.25)
  },

  containerTitle: {
    flexDirection: 'row',
    alignSelf: 'center',
    position: 'absolute',
    top: vh(42.5)
  },

  touchableOpacityImageButtonAdd: {
    position: 'absolute',
    top: vh(42.5),
    right: vw(35)
  },

  imageButtonAdd: {
    width: vw(5),
    height: vw(5)
  },

  containerFlatListQuestions: {
    position: 'absolute',
    alignSelf: 'center',
    top: vh(47.5)
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
  },
   styleBack: {
    right: vw(48),
   }
})
