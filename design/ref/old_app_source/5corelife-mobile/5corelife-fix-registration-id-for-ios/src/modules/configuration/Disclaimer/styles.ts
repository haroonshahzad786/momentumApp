import { StyleSheet } from 'react-native'
import { vh, vw } from '../../../helpers/dimensions'

export default StyleSheet.create({
  imageBackgroundContainer: {
    flex: 1
  },

  viewButtonBack: {
    position: 'absolute',
    top: vh(5.5),
    left: vw(5)
  },

  viewHeaderSettings: {
    alignSelf: 'center',
    position: 'absolute',
    top: vh(11)
  },

  viewElements: {
    alignSelf: 'center',
    position: 'absolute',
    top: vh(18),
    paddingHorizontal: vw(10)
  },

  textTitle: {
    marginVertical: vh(3),
    textAlign: 'center',
    textShadowOffset: {
      width: 1,
      height: 1
    },
    textShadowRadius: 5,
    elevation: 5
  },

  textSubtitle: {
    textAlign: 'center',
    lineHeight: vh(5),
    textShadowOffset: {
      width: 1,
      height: 1
    },
    textShadowRadius: 5,
    elevation: 5
  }
})
