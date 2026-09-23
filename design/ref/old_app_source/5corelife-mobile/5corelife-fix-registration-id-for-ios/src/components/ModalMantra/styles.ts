import { StyleSheet } from 'react-native'

import { vh, vw } from '../../helpers/dimensions'

export default StyleSheet.create({
  imageBackgroundContainer: {
    width: vw(107.5),
    height: vh(100),
    alignSelf: 'center',
    marginTop: -vh(5),
    overflow: 'hidden',
  },

  textTitle: {
    alignSelf: 'center',
    marginTop: vh(20.25)
  },

  touchableOpacityImageIconRight: {
    alignSelf: 'center',
    marginTop: vh(3.5),
    marginLeft: vw(75)
  },

  viewParagraphs: {
    marginTop: vh(1),
    paddingHorizontal: vw(15),
    height: vh(55),
  },

  textInputParagraphFirst: {
    //
  },

  textParagraphDivider: {
    alignSelf: 'center'
  },

  buttonDone: {
    position: 'absolute',
    alignSelf: 'center',
    bottom: vh(5)
  }
})
