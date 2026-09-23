import { StyleSheet } from 'react-native'

import { vw } from '../../helpers/dimensions'

export default StyleSheet.create({
  viewContainer: {
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center'
  },

  textTitle: {
    maxWidth: vw(60),
    textAlign: 'center'
  },

  viewImageRight: {
    position: 'absolute',
    right: vw(7.5)
  }
})
