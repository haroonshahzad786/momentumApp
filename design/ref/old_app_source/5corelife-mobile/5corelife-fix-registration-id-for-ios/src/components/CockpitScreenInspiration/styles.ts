import { StyleSheet } from 'react-native'

import { vw } from '../../helpers/dimensions'

export default StyleSheet.create({
  viewContainer: {
    flex: 1
  },

  imageBackgroundScreen: {
    width: vw(80),
    height: vw(80),
    alignSelf: 'center'
  },

  viewTitle: {
    position: 'absolute',
    top: vw(37.5),
    left: vw(15),
    width: vw(50),
    height: vw(35),
    justifyContent: 'center',
    alignItems: 'center'
  },

  textTitle: {
    alignSelf: 'center',
    textAlign: 'center'
  }
})
