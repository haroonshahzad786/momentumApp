import { StyleSheet } from 'react-native'
import { vh, vw } from '../../../helpers/dimensions'

export default StyleSheet.create({
  imageBackgroundContainer: {
    flex: 1,
    zIndex:1
  },

  navigationStyles: {
    marginTop: vh(5),
    marginHorizontal: vw(5),
    flexDirection: 'row',
    alignItems: 'center',
  },

  viewButtonBack: {
  },

  viewButtonHelp: {
  },

  viewHeaderSettings: {
    alignSelf: 'center',
  },

  viewElements: {
    alignSelf: 'center',
    //marginTop: vh(3)
  },

  viewCard: {
    width: vw(90),
    marginBottom: vh(2),
    paddingHorizontal: vw(5),
    paddingVertical: vh(1),
    borderRadius: 40,
    borderWidth: 3,
    shadowColor: '#000000',
    shadowOffset: {
      width: 20,
      height: 20
    },
    shadowOpacity: 0.75,
    shadowRadius: 12.5,
    elevation: 5
  },

  textCardTitle: {
    marginBottom: vh(1),
    textAlign: 'center'
  },

  imageCardLine: {
    width: vw(50),
    alignSelf: 'center',
    marginBottom: vh(1.5)
  },

  viewCheckIn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: vh(1)
  },

  textCardCheckInLabel: {
    marginRight: vw(5),
    textAlign: 'center'
  },

  textCardCheckInTime: {
    marginRight: vw(2.5),
    marginBottom: -vh(0.25),
    textAlign: 'center'
  },

  imageEdit: {
    width: vw(5),
    height: vw(5)
  },

  viewSwitch: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: vh(0.5)
  },

  textSwitch: {
    marginBottom: -vh(0.5),
    paddingHorizontal: vw(2.5)
  },

  textCardParagraph: {
    marginBottom: vh(1.5),
    textAlign: 'center'
  },

  viewButtonSettings: {
    width: vw(90)
  },

  buttonSettings: {
    width: vw(90),
    height: vh(7.5),
    marginBottom: vh(1.5),
    paddingHorizontal: vw(5),
    borderRadius: 40,
    borderWidth: 3,
    shadowColor: '#000000',
    shadowOffset: {
      width: 20,
      height: 20
    },
    shadowOpacity: 0.75,
    shadowRadius: 12.5,
    elevation: 5
  },

  imageButtonSettings: {
    width: vw(5),
    height: vw(5)
  },

  animatedViewScreen: {
    alignSelf: 'center',
    position: 'absolute',
    bottom: vh(125),
    zIndex: 3
  },

  imageBackgroundScreen: {
    width: vw(95),
    height: vw(150)
  },

  viewTextScreen: {
    width: vw(70),
    height: vw(40),
    marginTop: vw(85),
    justifyContent: 'center',
    alignItems: 'center',
    alignSelf: 'center'
  },

  textScreen: {
    textAlign: 'center',
    textAlignVertical: 'bottom',
    height: '65%'
  },

  buttons: {
    width: vw(10),
    height: vh(6)
  }
})
