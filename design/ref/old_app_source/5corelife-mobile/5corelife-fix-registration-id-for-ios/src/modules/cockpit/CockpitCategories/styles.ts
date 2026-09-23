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
    left: vw(17.5)
  },

  containerCockpitScreen: {
    position: 'absolute',
    top: -vh(1.75),
    right: vw(12.5)
  },

  containerFlatListCategories: {
    position: 'absolute',
    alignSelf: 'center',
    top: vh(40),
  },

  textModalMantraTitle: {
    textTransform: 'uppercase'
  },

  textModalMantraParagraph: {
    lineHeight: vh(4)
  },

  textDoneButton: {
    textShadowOffset: {
      width: 0.25,
      height: 1
    },
    textShadowRadius: 5
  },
  bubbleShape: {
    width: vw(56),
    height: vw(98.5),
    borderRadius: 20,
    justifyContent: 'flex-start',
    alignItems: 'center',
    paddingTop: 3,
    elevation: 20,
  },
  containerBubble: {
    // backgroundColor: 'yellow',
    width: vw(55),
    height: vw(97),
    overflow: 'hidden',
    paddingTop: 10,
    shadowColor: '#000000',
    elevation: 5,
    justifyContent: 'center',
    alignItems: 'center',
    borderRadius: 20,
  },
  
})
