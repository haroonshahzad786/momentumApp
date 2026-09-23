import { StyleSheet } from 'react-native'

import { vh,vw } from '../../helpers/dimensions'

export default StyleSheet.create({

  container: {
    flex: 1,
  },

  containerSub: {
    flex: 1,
    height:'100%'
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
    flexDirection:'row',
    alignItems:'center',
    justifyContent:'center',
    position:'relative'
  },
  containerBackCard:{
  },
  containerCardQuest: {
    marginHorizontal: vw(5.5),
  },
  containerRows: {
    borderRadius: 40,
    marginTop:vh(2.5),
  },
  containerScoreRow:{
    // backgroundColor:'red',
    flexDirection:'row',
    alignItems:'center',
    marginBottom:vh(2.5),
  },
  containerImageImprovementsIcon: {
  },
  imageImprovementsIcon: {
    width: vw(15),
    marginLeft:'-5%',
    minHeight: vw(15),
  },
  rowText:{
    flexDirection:'row',
    textShadowOffset: {
      width:0,
      height: 0
    },
    textShadowRadius: 2,
  },
  rowContainerData:{
    flexDirection:'row',
    paddingLeft:vw(8),
    width: '100%',
    alignItems:'center',
    height: vw(10),
  },
  rowBackground:{
    paddingLeft:vw(8),
    width: '100%',
    height: vw(10),
  },
  offsetContainerIcon:{
    position:'absolute',
    marginLeft:"-5%",
    zIndex:9
  },
  containerBubble:{
    width: vw(10),
    height: vw(10),

    overflow:'hidden',
    shadowColor: '#000000',
    elevation: 5,
    justifyContent:'center',
    alignItems:'center',
    borderRadius:500,
  },
  bubbleShape:{
    width: vw(10.5),
    height: vw(10.5),
    borderRadius:500,
    overflow:'hidden',
    justifyContent:'center',
    alignItems:'center',    
    elevation: 5,
  },
  iconBubble:{
    width: vh(5),
    height: vh(5),
  },
  bgRowCollapse:{
    width: vw(15),
    marginLeft:'-5%',
    minHeight: vw(15),
    position:'absolute',
  },
  butExpand:{
    width: vw(3),
    height: vw(2.2),
    marginLeft: 'auto', 
    marginRight: "5%", 
    // transform: [{ rotate: '180deg' }]
  },
  collapseDataContainer:{
    padding:'5%'
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
    paddingBottom:  vh(2),
    flexDirection:'row',
    justifyContent:'space-between',
    marginHorizontal: vw(2),
    // backgroundColor:'red'
  },
  textQuestHeader: {
    textAlign: 'center'
  },
  containerItemRowText:{
    marginHorizontal: vw(2),
    flexDirection:'row',
    justifyContent:'space-between',
  },
  divider:{
    borderWidth:0.4,
    width:'100%',
    marginVertical:vh(2),
    opacity:0.2
  },
  tailRow:{
    flexDirection:'row',
    alignItems:'center'
  },
  // editIcon:{
  //   width: vw(3),
  //   height: vw(3),
  //   marginLeft: 'auto', 
  //   marginRight: "5%", 
  // },
  linearGradient:{

  },
  buttonText:{

  }
})
