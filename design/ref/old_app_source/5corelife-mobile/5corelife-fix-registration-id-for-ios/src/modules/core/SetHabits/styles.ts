import { StyleSheet } from 'react-native'
import { RFValue } from 'react-native-responsive-fontsize'

import { vh, vw } from '../../../helpers/dimensions'

export default StyleSheet.create({
  imageBackgroundContainer: {
    flex: 1
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
    right: vw(5)
  },

  viewContinueButton: {
    position: 'absolute',
    alignSelf: 'center',
    alignItems: 'center',
    justifyContent: 'center',
    bottom: vh(4),
  },

  viewElements: {
    position: 'absolute',
    alignSelf: 'center',
    top: vh(30),
    flex: 1,
  },

  viewTitleText: {
    marginBottom: vh(2),
  },

  textTitle: {
    textAlign: 'center'
  },

  touchableOpacityImageButtonAdd: {
    position: 'absolute',
    right: 0
  },

  viewScoreProgress: {
    position: 'absolute',
    alignSelf: 'center',
    bottom: vh(11)
  },

  imageButtonAdd: {
    width: vw(7.5),
    height: vw(7.5)
  },

  viewListsHabits: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    width: vw(75),
    height: vh(30),
    overflow: 'hidden'
  },

  viewTextListsHabitsHeader: {
    marginBottom: vh(1.5)
  },

  marginTopTitle: {
    marginTop: vh(2)
  },

  textListsHabitsHeader: {
    textAlign: 'center'
  },

  viewListHabitsNegative: {
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

  viewTextListItemHabitSelected: {
    backgroundColor: 'rgba(255, 255, 255, 0.8)'
  },

  textListItemHabit: {
    textAlign: 'center',
    paddingVertical: vh(0.75),
    paddingHorizontal: vw(0.5)
  },

  viewListHabitsPositive: {
    //
  },

  viewScorePlanText: {
    marginTop: vh(2.5),
    marginBottom: vh(1.5)
  },

  textScorePlan: {
    textAlign: 'center'
  },

  viewScorePlanImage: {
    alignSelf: 'center'
  },

  imageScorePlan: {
    width: vw(65),
    height: vh(5)
  },

  containerHeaderSettings: {
  },

  imageButtonModal: {
    width: vw(17.5),
    height: vw(17.5)
  },

  textInputModal: {
    fontSize: RFValue(32)
  },
  loader: {


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
    marginTop: vh(8),
    position: 'absolute',
    zIndex: 9
  },
  textDoneButton: {
    textShadowOffset: {
      width: 0.25,
      height: 1,
    },
    textShadowRadius: 5,
  },
  textModalMantraParagraph: {
    lineHeight: vh(4)
  },
})
