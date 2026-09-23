import { StyleSheet } from 'react-native'

import { vh, vw } from '../../helpers/dimensions'

export default StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#000000'
  },

  containerImageBackgroundCockpit: {
    width: vw(120),
    height: vh(100),
    marginLeft: -vw(10),
  },

  containerButtonBack: {
    // position: 'absolute',
    // right: vw(28.5),
    // zIndex: 3,
    transform: [
      { rotate: '180deg' }
    ]
  },

  containerCockpitScreen: {
    alignSelf: 'center',
    position: 'absolute',
    top: -vh(30)
  },

  textInspiration: {
    lineHeight: vh(3.25)
  },

  containerTitle: {
    flexDirection: 'row',
    alignSelf: 'center',
    alignContent: 'center',
    position: 'absolute',
    top: vh(40),
    width: '50%',
    justifyContent: 'space-between'
  },

  touchableOpacityImageButtonAdd: {
    // position: 'absolute',
    // top: vh(42.5),
    // right: vw(35),
    // zIndex: 9
  },

  imageButtonAdd: {
    width: vw(5),
    height: vw(5)
  },

  containerFlatListQuestions: {
    // position: 'absolute',
    // alignSelf: 'center',
    // top: vh(47.5),
    // height: '43%',
    flexGrow: 1
    // backgroundColor: 'yellow'
  },

  containerButtonDone: {
    zIndex: 1,
    position: 'absolute',
    alignSelf: 'center',
    width: vw(22.5),
    bottom: vh(11.5)// vh(9.5)
  },

  buttonDone: {
    textShadowOffset: {
      width: 0.25,
      height: 1
    },
    textShadowRadius: 5
  },

  styleFuneral: {
    fontSize: vw(3.5),
    paddingRight: vw(0),
    textAlign: 'center'
  },

  containerCock: {
    position: 'absolute',
    top: '40%',
    left: '26.6%',
    overflow: 'hidden',
    width: vw(56),
    height: vh(50),
    // backgroundColor: 'red',
    zIndex: 10
  },

  containerCollapse: {
    zIndex: 2,
    flex: 1,
    marginTop: vh(2)
  },

  arrowSelecting: {
    width: vh(2),
    // backgroundColor:'blue',
  },

  arrowThree: {
    opacity: 0.6,
  },

  containerDrawer: {
    position: 'absolute', 
    top: '44%', 
    // left: '28.5%', 
    left: '26.5%', 
    height: '49%', 
    overflow: 'hidden', 
    width: '47%'
  },
  bubbleShape: {
    width: vw(56),
    height: vw(80),
    borderRadius: 20,
    justifyContent: 'flex-start',
    alignItems: 'center',
    paddingTop: 3,
    elevation: 20,
  },
  containerBubble: {
    width: vw(55),
    height: vw(79),
    overflow: 'hidden',
    paddingTop: 10,
    shadowColor: '#000000',
    elevation: 5,
    justifyContent: 'flex-start',
    alignItems: 'center',
    borderRadius: 20,
  },
})
