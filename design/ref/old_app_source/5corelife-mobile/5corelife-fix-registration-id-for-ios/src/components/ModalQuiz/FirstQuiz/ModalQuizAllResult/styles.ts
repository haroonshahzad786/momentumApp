import { StyleSheet } from 'react-native'
import { vh, vw } from '../../../../helpers/dimensions'

export default StyleSheet.create({

  topSection: {
    flexBasis: '32%',
    alignItems: 'center',
    // backgroundColor: '#FF000044',
  },

  quizTitle: {
    alignSelf: 'center',
    marginTop: vh(4.6),
    textAlign: 'center',
  },
  quizSubtitle: {
    alignSelf: 'center',
    marginTop: vh(6.5),
    textAlign: 'center',
    fontSize: vw(10)
  },
  middleSection: {
    flexBasis: '11%',
    alignItems: 'stretch',
    flexDirection: 'row',
    justifyContent: 'space-around'
    // backgroundColor: '#00FF0044',
  },
  bubbleShape: {
    width: vw(14),
    height: vw(14),
    borderRadius: 500,
    justifyContent: 'center',
    alignItems: 'center',
    elevation: 20,
  },
  containerBubble: {
    width: vw(13),
    height: vw(13),
    overflow: 'hidden',
    shadowColor: '#000000',
    elevation: 5,
    justifyContent: 'center',
    alignItems: 'center',
    borderRadius: 500,
  },
  titleCore: {
    height: '100%',
    justifyContent: 'center',
    marginRight: vw(8)
  },
  textCore: {
    fontSize: vw(7),
    marginLeft: vw(2),
    fontWeight: '600',
    textAlign: 'left'
  },
  subTitleCore: {
    height: '100%',
    marginLeft: vw(5),
    justifyContent: 'center'
  },
  what: {
    height: vh(6.5),
    width: vw(8)
  },
  sizeImageCore: {
    height: vh(13),
    width: vw(20)
  }
})
