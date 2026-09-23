import { StyleSheet } from 'react-native'

import { vh, vw } from '../../../helpers/dimensions'

export default StyleSheet.create({
  imageBackgroundContainer: {
    flex: 1,
  },

  viewButtonBack: {
    position: 'absolute',
    top: vh(5.5),
    left: vw(5),
    zIndex: 2,
  },

  viewCockpitScreen: {
    position: 'absolute',
    top: vh(0),
    right: vw(5),
  },

  viewContinueButton: {
    position: 'absolute',
    alignSelf: 'center',
    justifyContent: 'center',
    alignItems: 'center',
    bottom: vh(4),
  },

  viewElements: {
    position: 'absolute',
    alignSelf: 'center',
    //backgroundColor:'red'
  },

  marginTopText: {
    marginBottom: vh(3),
  },

  textTitle: {
    textAlign: 'center',
  },

  touchableOpacityImageButtonPencil: {
    position: 'absolute',
    right: 0,
  },
  marginTopTitle: {
    top: vh(33),
  },
  imageButtonPencil: {
    width: vw(6),
    height: vw(6),
  },

  viewScoreHabits: {
    position: 'absolute',
    alignSelf: 'center',
    bottom: vh(30),
    width: vw(75),
  },

  viewScoreProgress: {
    position: 'absolute',
    alignSelf: 'center',
    bottom: vh(11),
  },

  viewTextListItemHabitSelected: {
    alignSelf: 'center',
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: vh(1.5),
    paddingHorizontal: vw(5),
    borderRadius: 20,
    backgroundColor: 'rgba(255, 255, 255, 0.8)',
  },

  textListItemHabit: {
    textAlign: 'center',
    paddingVertical: vh(0.75),
    paddingHorizontal: vw(0.5),
  },

  viewScoreHabit: {
    width: vw(12.5),
    height: vw(12.5),
    borderRadius: 50,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.75)',
    backgroundColor: 'rgba(0, 0, 0, 0.8)',
  },

  viewScoreHabitSelected: {
    width: vw(17.5),
    height: vw(17.5),
    borderRadius: 50,
    borderWidth: 1,
    borderColor: 'rgba(0, 0, 0, 0.25)',
    backgroundColor: 'rgba(255, 255, 255, 0.8)',
  },

  flatList: {
    height: vh(21),
  },
  flatListExtended: {
    height: vh(36),
  },
  flatListOffset: {
    marginTop: -12,
  },
  spacerView: {
    height: 20,
  },
  fullHeight: { height: '100%' },

  containerHeaderSettings: {
  },
  viewListHabitsPositive: {
    //
  },
  viewTextListItemHabit: {
    minWidth: vw(35),
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: vh(1),
    borderRadius: 20,
    backgroundColor: 'rgba(255, 255, 255, 0.4)'
  },

  viewTextListsHabitsHeader: {
    marginBottom: vh(1.5)
  },
  textListsHabitsHeader: {
    textAlign: 'center'
  },
  viewListHabitsNegative: {
    //
  },
  viewListsHabits: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    width: vw(75),
    marginTop: vh(1),
    height: vh(29),
  },

  viewButton: {
    alignItems: 'center',
    justifyContent: 'center',
  },

  buttonSetHabitsContainer: {
    paddingHorizontal: vw(5.5),
    paddingVertical: vh(1.75),
    borderRadius: vw(10),
  },
  ///////////////////////
  // ONBOARDING STYLES.
  ///////////////////////

  darkVeil: {
    backgroundColor: 'rgba(0,0,0,0.6)'
  },
  lowOpacity: {
    opacity: 0.5
  },
  arrowIndicatorPosition: {
    position: 'absolute',
    left: vh(5)
  },
  arrowIndicatorPositionDone: {
    position: 'absolute',
    left: vh(5)
  },
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
})
