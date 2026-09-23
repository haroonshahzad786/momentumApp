import { StyleSheet } from 'react-native'

import { vh, vw } from '../../helpers/dimensions'

export default StyleSheet.create({
  quizTitle: {
    alignSelf: 'center',
    marginTop: vh(4.6),
    textAlign: 'center',
  },
  quizSubtitle: {
    alignSelf: 'center',
    marginTop: vh(3.5),
    textAlign: 'center',
  },
  quizQuestionsHeader: {
    alignSelf: 'center',
    marginTop: vh(1.8),
    textAlign: 'center',
  },
  topSection: {
    flexBasis: '32%',
    alignItems: 'center',
    // backgroundColor: '#FF000044',
  },
  middleSection: {
    flexBasis: '51%',
    alignItems: 'stretch',
    // backgroundColor: '#00FF0044',
  },
  bottomSection: {
    flexBasis: '17%',
    alignItems: 'center',
    // backgroundColor: '#0000FF44',
  },
  cubeImage: {
    width: vw(50),
    height: vh(20),
  },
  titleImage: {
    width: vw(55),
    height: vh(25),
    position: 'absolute',
    top: vh(14),
  },
  titleImageFailed: {
    width: vw(55),
    height: vh(20),
    position: 'absolute',
    top: vh(18),
    left: vw(15),
  },
  titleImageCompleted: {
    width: vw(75),
    height: vh(20),
    position: 'absolute',
    top: vh(16),
  },
  xImage: {
    width: vw(13),
    height: vh(8),
    position: 'absolute',
    top: vh(10),
  },
  daysContainer: {
    marginTop: vh(4),
  },
  questDescription: {
    marginTop: vh(0),
    width: vw(40),
    textAlign: 'center',
  },
  lineImage: {
    position: 'absolute',
    // marginLeft: vw(4),
    top: vh(5.5),
    left: vw(2),
    width: vw(80),
    height: vh(0.1),
  },
  rewardImage: {
    width: vw(20),
    height: vh(5),
    position: 'absolute',
    top: vh(-2.5),
  },
  rewardTitle: {
    position: 'absolute',
    top: vh(-1.5),
  },
  rewardAmountContainer: {
    marginTop: vh(4),
    flexDirection: 'row',
    alignItems:'center',
    justifyContent:'center',
    marginLeft:vh(1)
  },
  coinImage: {
    width: vw(18),
    height: vh(10),
  },
  questionHeader: {
    // backgroundColor: '#FF000055',
    flexBasis: '15%',
  },
  questionBlock: {
    // backgroundColor: '#00FF0055',
    flexBasis: '85%',
  },
  questionRow: {
    flexGrow: 1,
    flexDirection: 'row',
    alignItems: 'stretch',
    flexShrink: 0,
    flexBasis: 0,
  },
  questionTickContainer: {
    height: '100%',
    flexBasis: '25%',
    alignItems: 'stretch',
    padding: '4%',
  },
  questionTick: {
    width: '100%',
    flexGrow: 1,
  },
  questionTextContainer: {
    textAlignVertical: 'center',
    flexBasis: '75%',
  },
  quizScoreTextContainer: {
    textAlignVertical: 'center',
    marginTop: vh(1.5),
  },
})
