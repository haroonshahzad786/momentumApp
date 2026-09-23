import { StyleSheet } from 'react-native'

import { vh, vw } from '../../helpers/dimensions'

export default StyleSheet.create({

  container: {
    flex: 1,
  },

  containerSub: {
    flex: 1,
    height: '100%'
  },

  containerButtonBack: {
    position: 'absolute',
    top: vh(5.5),
    left: vw(5),
    zIndex: 9
  },
  containerButtonNext: {
    position: 'absolute',
    right: vw(13),
  },
  containerHeaderSettings: {
    marginTop: vh(11),
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    position: 'relative'
  },
  containerBackCard: {
  },
  containerCardQuest: {
    marginRight: vw(2.9),
    marginLeft: vw(7),
    height: vh(28),
  },
  containerRows: {
    borderRadius: 40,
    marginTop: vh(2.5),
  },
  containerScoreRow: {
    // backgroundColor:'red',
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: vh(2.5),
  },
  containerImageImprovementsIcon: {
  },
  imageImprovementsIcon: {
    width: vw(15),
    marginLeft: '-5%',
    minHeight: vw(15),
  },
  rowText: {
    flexDirection: 'row',
    textShadowOffset: {
      width: 0,
      height: 0
    },
    textShadowRadius: 2,
    marginLeft: 24,
    textAlign: 'left',
    flex: 1
  },
  rowContainerData: {
    marginLeft: vw(5),
    flexDirection: 'row',
    paddingLeft: vw(8),
    width: '94%',
    alignItems: 'center',
    height: vw(10),
  },
  rowBackground: {
    paddingLeft: vw(8),
    width: '94%',
    height: vw(10),
  },
  offsetContainerIcon: {
    flex: 1,
    position: 'absolute',
    // marginLeft:"-5%",
    zIndex: 9
  },
  containerBubble: {
    width: vw(17),
    height: vw(17),
    overflow: 'hidden',
    shadowColor: '#000000',
    elevation: 5,
    justifyContent: 'center',
    alignItems: 'center',
    borderRadius: 500,
  },
  bubbleShape: {
    width: vw(18),
    height: vw(18),
    borderRadius: 500,
    justifyContent: 'center',
    alignItems: 'center',
    elevation: 20,
  },
  iconBubble: {
    width: vh(10),
    height: vh(9),
    padding: 20
  },
  bgRowCollapse: {
    width: vw(15),
    marginLeft: '-5%',
    minHeight: vw(15),
    position: 'absolute',
  },
  butExpand: {
    width: vw(3),
    height: vw(2.2),
    marginLeft: 'auto',
    marginRight: "5%",
    // transform: [{ rotate: '180deg' }]
  },
  collapseDataContainer: {
    padding: '5%'
  },
  header: {
    backgroundColor: '#F5FCFF',
    padding: 10,
  },
  active: {
    transform: [{ rotate: '0deg' }]
  },
  inactive: {
    transform: [{ rotate: '180deg' }]

  },
  content: {
    padding: 20,
    backgroundColor: '#fff',
  },
  containerCardQuestTextHeader: {
    marginBottom: vh(0.5),
    paddingBottom: vh(2),
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginHorizontal: vw(2),
    // backgroundColor:'red'
  },
  textQuestHeader: {
    textAlign: 'left',
    fontSize: vw(10),
    marginLeft: 20,
    letterSpacing: 1
  },
  containerItemRowText: {
    marginHorizontal: vw(2),
    flexDirection: 'row',
    justifyContent: 'space-between',
    height: '100%'
  },
  divider: {
    borderWidth: 0.4,
    width: '100%',
    marginVertical: vh(2),
    opacity: 0.2
  },
  tailRow: {
    flexDirection: 'row',
    alignItems: 'center'
  },
  // editIcon:{
  //   width: vw(3),
  //   height: vw(3),
  //   marginLeft: 'auto', 
  //   marginRight: "5%", 
  // },
  linearGradient: {

  },
  buttonText: {

  },
  sliderBox: {
    width: '100%',
    zIndex: 9,
    height: '90%',
    display: 'flex',
    justifyContent: 'center',
    alignContent: 'center',

    // height: vh(27),
    // marginTop: '2%',
    // marginRight:vh(18),
    // backgroundColor:'red'
  },
  slider: {
    // marginTop: 130,
    // zIndex: 9,
    // position: 'absolute',
    width: '90%',
    // backgroundColor:'yellow'
  },
  numberSliderValue: {
    color: 'white'
  },
  containerSlide: {
    marginHorizontal: vw(5.5),
    flexDirection: 'row',
    // alignItems:'center',
    justifyContent: 'center',
    zIndex: 1,
    width: '80%',
  },
  collapsible: {
    height: vh(30)
  },
  point: {
    // transform: [{ rotate: '360deg', },],
    position: 'absolute',
    top: '5%',
  },
  congrats: {
    height: vh(10),
    width: vh(10),
    position: 'absolute',
    // marginTop:vh(5),
    // backgroundColor:'red'
  },
  alignAndroidValue: {

  },
  alignIosValue: {
    left: '58%'
  },
  alignIosCongrats: {
    left: vw(20)
  }
})
