import { StyleSheet } from 'react-native'

import { vh, vw } from '../../helpers/dimensions'

export default StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    alignSelf: 'center',
    width: vw(50),
    marginBottom: vh(1),
    borderRadius: 5,
    shadowColor: '#000000',
    shadowOffset: {
      width: 0,
      height: 5
    },
    shadowOpacity: 0.5,
    shadowRadius: 10,
    elevation: 5
  },

  containerTextTitle: {
    paddingVertical: vh(1.5)
  },

  textTitle: {
    textAlign: 'center'
  },

  containerImageArrow: {
    position: 'absolute',
    top: vh(1.5),
    right: vw(2.5)
  },

  imageArrow: {
    width: vw(3),
    height: vh(2)
  },

  containerImageLock: {
    position: 'absolute',
    top: vh(0.125),
    right: vw(0)
  },

  imageLock: {
    width: vw(8),
    height: vh(5)
  }
})
