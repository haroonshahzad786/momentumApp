import { StyleSheet } from 'react-native'

import { vh, vw } from '../../helpers/dimensions'
import HelpItem from '../HelpItem'

export default StyleSheet.create({
  container: { alignSelf: 'center', marginBottom: vh(2) },

  containerTextSubitle: {
    alignSelf: 'center',
    marginBottom: vh(0.5)
  },

  textSubtitle: {
    textShadowOffset: {
      width: 0.25,
      height: 1
    },
    textShadowRadius: 5,
    elevation: 5
  },

  containerTextTitle: {
    alignSelf: 'center',
    marginBottom: vh(0.5),
    justifyContent:'center',
    alignItems:'center',
  },

  textTitle: {
    textShadowOffset: {
      width:0,
      height: vh(0.5)
    },
    textShadowRadius: vh(1),
  },

  containerImageLine: {
    marginBottom: vh(0.5)
  },

  imageLine: {
    width: vw(85),
    alignSelf: 'center'
  },

  containerArrowLeft: {
    flex: 0.5,
    justifyContent: 'space-evenly',
    alignItems: "center",
  },
  arrowSize:{
    width: vh(2.5),
    height:vh(4),
  },

  arrowLeft: {
    width: vh(4),
    height:vh(5)
  },

  containerArrowRight: {
    flex: 0.5,
    justifyContent: 'space-evenly',
    alignItems: "center",
  },

  arrowRight: {
    width: vw(6)
  },

  leftDirection:{
    transform:[{ rotate: '180deg' }]
  },

  offsetContainerIcon:{
    alignItems:'center',
    justifyContent:'center',
    marginTop:vh(11.5),
    alignSelf: 'center',
  },

  bubbleShape:{
    width: vh(16),
    height: vh(16),
    borderRadius:500,
    overflow:'hidden',
    justifyContent:'center',
    alignItems:'center',    
    elevation: 5,
  },

  iconBubble:{
    width: vh(15),
    height: vh(15),
  },

  containerBubble:{
    width: vh(15),
    height: vh(15),
    overflow:'hidden',
    shadowColor: '#000000',
    elevation: 5,
    justifyContent:'center',
    alignItems:'center',
    borderRadius:500,
  },

  textCore:{
    width: vh(20),
    height: vh(10),
    position:'absolute',
    top:-vh(7),
  },

  avatarContainer:{
    flexDirection: 'row', 
    alignItems: 'center', 
    justifyContent: 'space-evenly',
    width: vh(40),
  },

  lightBackground:{
    width:vh(40),
    height:vh(20),
    position:'absolute',
    top:-vh(5),
    opacity:0.4,
    zIndex:0
    // backgroundColor:'red',
  }
})
