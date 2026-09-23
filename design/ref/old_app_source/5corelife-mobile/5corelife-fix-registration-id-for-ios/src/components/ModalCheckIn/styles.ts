import { StyleSheet } from 'react-native'

import { vh, vw } from '../../helpers/dimensions'

export default StyleSheet.create({
  textTitle: {
    alignSelf: 'center',
    marginTop: vh(4.6),
    textAlign: 'center',
  },
  topSection: {
    flexBasis: '40%',
    alignItems: 'stretch',
    // backgroundColor: '#00FF00AA',
  },
  middleSection: {
    flexBasis: '35%',
    alignItems: 'stretch',
    flexDirection: 'row',
    paddingTop: vh(11),
    paddingBottom: vh(2),
    paddingHorizontal: vw(5),
    // backgroundColor: '#0000FFAA',
  },
  bottomSection: {
    flexBasis: '25%',
    alignItems: 'center',
  //  backgroundColor: '#FF0000AA',
  },
  cubeImage: {
    width: vw(50),
    height: vh(20),
  },
  centeredAbsolute: {
    position: 'absolute',
    left: '50%',
  },
  titleImage: {
    width: vw(80),
    height: vh(30),
    left: '-50%',
    top: vh(21),
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
    // backgroundColor:'red',
    marginTop: vh(4),
    flexDirection: 'row',
    alignItems:'center',
    justifyContent:'center',
    
  },
  coinImage: {
    width: vw(12),
    height: vh(6),
    // backgroundColor:'green',
  },
  halfFlex: {
    flexGrow: 1,
    flexBasis: 0,
    justifyContent: 'center',
  },
  mainContentNumber: {
    textAlign: 'center',
  },
  mainContentDescription: {
    textAlign: 'center',
    marginTop: vh(-1),
  },
  statRow: {
    flexDirection: 'row',
    justifyContent: 'space-evenly',
    flexGrow: 1,
    flexBasis: 0,
    flexShrink: 0,
    alignItems: 'center',
  },
  statsContainer: {
    // backgroundColor: 'red',
    marginTop: vh(1.5),
    height: vh(15),
  },
  textTitles:{
    
  }
})
