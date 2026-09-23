import { StyleSheet } from 'react-native'

import { vh, vw } from '../../../helpers/dimensions'

export default StyleSheet.create({
  container: {
    flex: 1,
  },

  containerSub: {
    flex: 1,
  },

  containerImageBackground: {
    height: vh(160),
    alignItems: 'center',
    justifyContent: 'center'
    // marginTop: -vh(1),
    // marginLeft: -vw(50),
  },
  containerPlanets: {
    width: '100%',
    height: '100%',
    justifyContent: 'center',
    alignItems: 'center'
  },

  rocketRoad: {
    // borderColor:'green',
    // borderWidth:0.5,
    height: '100%',
    width: vh(10),
    alignItems: 'center',
  },

  containerTWF: {
    flex: 1,
    backgroundColor: 'red'
  },

  modalJourneyOpacityContainerButton: {
    width: vw(25),
    height: vh(7),
    borderRadius: vw(10),
    borderWidth: vw(0.5),
  },

  modalJourneyTextDoneButton: {
    textShadowOffset: {
      width: 0.25,
      height: 1,
    },
    textShadowRadius: 5,
  },

  modalMantraTextTitle: {
    textTransform: 'uppercase',
  },

  modalMantraTextParagraph: {
    lineHeight: vh(4),
  },

  modalMantraTextDoneButton: {
    textShadowOffset: {
      width: 0.25,
      height: 1,
    },
    textShadowRadius: 5,
  },
  modalMantraIconRightImage: {
    width: vw(5),
    height: vw(5),
  },
  modalMantraOpacityContainerButton: {
    width: vw(25),
    height: vh(7),
    borderRadius: vw(10),
    borderWidth: vw(0.5),
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
  ///////////
  rocketLocation: {
    width: vh(5),
    height: vh(7),
    // backgroundColor:'red',
  },

  imageRocket: {
    // backgroundColor:'yellow',
    width: '100%',
    height: '100%',
  },

  containerButtonNext: {
    position: 'absolute',
    bottom: vh(1),
    right: vw(1),
  },
  buttonNext: {
    width: vw(15),
    height: vh(10)
  },
  modalQuizTextDoneButton: {
    textShadowOffset: {
      width: 0.25,
      height: 1,
    },
    textShadowRadius: 5,
  },
})
