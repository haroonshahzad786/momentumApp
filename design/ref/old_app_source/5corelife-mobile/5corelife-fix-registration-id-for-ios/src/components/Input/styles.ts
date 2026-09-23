import { StyleSheet } from 'react-native'

import { vh, vw } from '../../helpers/dimensions'

export default StyleSheet.create({
  container: {
    //
  },

  containerTextLabel: {
    marginBottom: vh(1),
    paddingLeft: vw(3.5)
  },

  containerIconError: {
    position: 'absolute',
    top: vh(3.75),
    left: vw(1.5),
    zIndex: 1
  },

  containerTextInput: {
    width: '100%',
    height: vh(5),
    borderWidth: 1,
    paddingVertical: vh(1),
    paddingHorizontal: vw(3.5),
    textAlign: 'center'
  },

  containerIconSecure: {
    position: 'absolute',
    top: vh(3.75),
    right: vw(5),
    zIndex: 1
  }
})
