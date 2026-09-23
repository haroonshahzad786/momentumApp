import { StyleSheet } from 'react-native'

import { vh, vw } from '../../helpers/dimensions'

export default StyleSheet.create({
  textTitle: {
    alignSelf: 'center',
    marginTop: vh(20.25),
  },
  topSection: {
    flexBasis: '40%',
    alignItems: 'center',
  },
  middleSection: {
    flexBasis: '34%',
    alignItems: 'center',
  },
  bottomSection: {
    flexBasis: '26%',
    alignItems: 'center',
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
    marginTop: vh(2),
  },
  questOrMissionTitle: {
    marginTop: vh(0),
    width: vw(60),
    textAlign: 'center',
    letterSpacing: 0,
    fontSize: vw(7)
  },
  questOrMissionDescription: {
    marginTop: vh(0),
    width: vw(80),
    textAlign: 'center',
    letterSpacing: 0,
  },
  lineImage: {
    marginLeft: vw(0),
    width: vw(80),
    height: vh(0.1),
  },
  rewardTitleContainer: {
    width: vw(25),
    height: vh(5),
    position: 'absolute',
    top: vh(-2.5),
    borderRadius: 20,
    backgroundColor: '#000000',
    borderStyle: 'solid',
    borderColor: '#fff3f375',
    borderWidth: 1.5,
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
    width: vw(12),
    height: vh(6),
  },
})
