import { StyleSheet } from 'react-native'
import { vh, vw } from '../../../helpers/dimensions'

export default StyleSheet.create({
  imageBackgroundContainer: {
    flex: 1
  },

  viewButtonBack: {
    position: 'absolute',
    top: vh(5.5),
    left: vw(5),
    zIndex: 9
  },

  viewHeaderSettings: {
    position: 'absolute',
    top: vh(5),
    height: vh(10)
  },

  scrollViewContainer: {
    alignSelf: 'center',
    position: 'absolute',
    top: vh(20),
    paddingHorizontal: vw(10),
    height: vh(80)
  },

  scrollViewContainerContent: {
    //
  },

  viewElements: {
    //
  },

  viewSection: {
    marginTop: vh(2.5)
  },

  textTitle: {
    marginBottom: vh(1)
  },

  textSubtitle: {
    lineHeight: vh(3.25)
  },

  textLine: {
    textAlign: 'center'
  }
})
