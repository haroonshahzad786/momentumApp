import { StyleSheet } from 'react-native'

import { vh, vw } from '../../../helpers/dimensions'

export default StyleSheet.create({
  quizTitle: {
    alignSelf: 'center',
    marginTop: vh(4.6),
    textAlign: 'center',
  },
  quizTitleEdit:{
    alignSelf: 'center',
    marginTop: vh(4.6),
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
    flexBasis: '5%',
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
  questionRow: {
    flexGrow: 1,
    flexDirection: 'row',
    flexShrink: 0,
    flexBasis: 0,
    justifyContent:'center',
    alignItems:'center',
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
    backgroundColor:'red'
  },
  formedHabitButton: {
    textAlignVertical: 'center',
    marginTop: vh(1.5),
  },
  questionTickCharacter: {
    position: 'absolute',
    top: vh(2.8),
    left: vw(7.2),
  },
  viewSwitch: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
  },
  textSwitch: {
    marginBottom: -vh(0.5),
    paddingHorizontal: vw(2.5)
  },
  inputDescription:{
    backgroundColor:'green'
  },
  descriptionBox:{
    marginHorizontal: vw(7.2),
    marginBottom:vh(2.2),
  },
  sizeSwitcher:{
    marginTop:5,
    transform: [{ scaleX: 1.2 }, { scaleY: 1.2 }] 
  },
  editIcon:{
    width: vw(4),
    height: vw(4),
    //marginRight: vw(2),
    marginLeft:vw(2),
  },
  favIcon:{
    width: vw(5),
    height: vw(4),
  },
  editIconBox:{
    top: vh(3),
    marginLeft:'auto',
    textAlign: 'center',
    flexDirection:'row',
    justifyContent:'flex-end',
    width:vw(20),
    marginRight: vw(5),
  },

  titleSection:{
    flexDirection:'row',
  },

  titleBox:{
    marginTop:'5%'
  },

  inputTitle:{
    textAlign: 'center', 
    textAlignVertical: 'top',
    width:vw(55),
  
  },

  dropDownPicker: {
    width: '100%',
  }
})
