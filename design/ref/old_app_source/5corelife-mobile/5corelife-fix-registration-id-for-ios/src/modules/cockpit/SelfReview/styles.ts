import { StyleSheet } from 'react-native'
import { vintage } from 'react-native-color-matrix-image-filters'

import { vh, vw } from '../../../helpers/dimensions'

export default StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#000000',
  },

  containerImageBackgroundCockpit: {
    width: vw(120),
    height: vh(100),
    marginLeft: -vw(10),
  },

  containerButtonBack: {
    position: 'absolute',
    top: vh(4),
    left: vw(17.5),
  },

  containerCockpitScreen: {
    position: 'absolute',
    top: -vh(1.75),
    right: vw(12.5),
  },

  containerTextTitle: {
    alignSelf: 'center',
    flexDirection:'row',
   
    // backgroundColor:'red',
    width: '46%',
  },
  panelContainer:{
    width:"100%",
    top: vh(39),
    // backgroundColor:'red'
  },
  
  containerFlatListQuestions: {
    position: 'absolute',
    alignSelf: 'center',
    top: vh(5),
  },

  containerButtonDone: {
    position: 'absolute',
    alignSelf: 'center',
    width: vw(22.5),
    bottom: vh(9.5),
  },

  buttonDone: {
    textShadowOffset: {
      width: 0.25,
      height: 1,
    },
    textShadowRadius: 5,
  },
  modalQuestTextDoneButton: {
    textShadowOffset: {
      width: 0.25,
      height: 1,
    },
    textShadowRadius: 5,
  },
  modalQuestOpacityContainerButton: {
    width: vw(25),
    height: vh(7),
    borderRadius: vw(10),
    borderWidth: vw(0.5),
  },
  modalCheckInTextDoneButton: {
    textShadowOffset: {
      width: 0.25,
      height: 1,
    },
    textShadowRadius: 5,
  },

  arrowSize:{
    // backgroundColor:'red',
    height:vh(2.5),
    width:vh(1.5),
  },
  titleAlign:{
    textAlign: 'center',
    width: '100%'
  },
  arrowContainer: {
    alignItems: 'flex-end',
    alignSelf: 'flex-end',
    // right:vh(5.5)
  },

  // MANTRA // 
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
  imageSeparator: {
    height:vh(.5),
    width:'100%',
    marginVertical:vh(0.5),
  },
  okBtn: {
    width: vw(30),
    marginTop: vh(10)
    // top: '50%'
  },
  alien1: {
    marginTop: vh(16.5),
    height: vw(140),
  },
  imageButtonModal: {
    width: vw(13.5),
    height: vw(13.5)
  },
})
