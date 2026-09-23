import { StyleSheet } from 'react-native'

import { vh, vw } from '../../helpers/dimensions'

export default StyleSheet.create({
  bgModal: {
    width: '100%',
    height: '100%',
    backgroundColor: 'rgba(0,0,0,.3)',
    alignContent: 'center',
    justifyContent: 'center',
  },
  imageBackgroundContainer: {
    flex: 1,
  },

  safeAreaViewContainer: {
    flex: 1,
  },

  buttonNextStepPosition: {
    alignSelf: 'flex-end',
    marginRight: vh(2),
    marginTop: 'auto',
  },

  imagePlanet: {
    height: vh(35),
    position: 'absolute',
    bottom: vh(25),
    width: '100%'
  },

  imageRocket: {
    height: vh(35),
    position: 'absolute',
    width: '100%',
    bottom: vh(44),
    zIndex: 2,
  },
  imageRocketLanding: {
    height: vh(35),
    position: 'absolute',
    right: -vw(17),
    width: '100%',
    bottom: vh(24),
    zIndex: 2,
  },
  imageTwoPlanet: {
    width: vw(35),
    height: vh(35)
  }
})
