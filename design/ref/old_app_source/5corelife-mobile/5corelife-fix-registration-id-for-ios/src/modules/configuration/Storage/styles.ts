import { StyleSheet } from 'react-native'
import { RFValue } from 'react-native-responsive-fontsize'

import { vh, vw } from '../../../helpers/dimensions'

export default StyleSheet.create({
  container: {
    flex: 1,
  },

  containerSub: {
    flex: 1,
  },

  navigationStyles: {
    marginTop: vh(5),
    marginHorizontal: vw(5),
    flexDirection: 'row',
    alignItems: 'center',
  },
  viewButtonBack: {
  },

  containerHeaderSettings: {
    marginTop: vh(11),
  },

  containerCardQuest: {
    marginHorizontal: vw(7.5),
    marginTop: vh(1.5),
    paddingHorizontal: vw(15),
    paddingTop: vh(1.5),
    paddingBottom: vh(2.5),
    borderRadius: 40,
    borderWidth: 3,
    shadowColor: '#000000',
    shadowOffset: {
      width: 20,
      height: 20,
    },
    shadowOpacity: 0.75,
    shadowRadius: 12.5,
    elevation: 5,
  },

  containerCardQuestTextHeader: {
    marginBottom: vh(1.5),
  },

  textQuestHeader: {
    textAlign: 'center',
  },

  containerCardQuestImageLine: {
    marginBottom: vh(1.75),
  },

  imageCardQuestLine: {
    width: vw(60),
    alignSelf: 'center',
  },

  containerCardQuestTextTitle: {
    marginBottom: vh(0.75),
  },

  textQuestTitle: {
    textAlign: 'center',
  },

  containerCardQuestTextDescription: {
    //
  },

  textQuestDescription: {
    textAlign: 'center',
    lineHeight: RFValue(24),
  },

  containerImprovements: {
    position: 'absolute',
    top: vh(46.5),
    left: vw(22.5),
  },

  containerImageImprovementsText: {
    marginBottom: -vh(6),
  },

  imageImprovementsText: {
    width: vw(55),
    height: vh(9)
  },

  containerImageImprovementsIcon: {
    marginLeft: -vw(2.5),
  },

  imageImprovementsIcon: {
    width: vw(75),
    height: vh(37.5),
  },

  containerTrophies: {
    position: 'absolute',
    top: vh(72),
    left: vw(7.5),
  },

  containerImageTrophiesText: {
    marginBottom: -vh(1),
  },

  imageTrophiesText: {
    width: vw(35),
    height: vh(9)
  },

  containerImageTrophiesIcon: {
    marginLeft: -vw(1.25),
    marginTop: -vh(3)
  },

  imageTrophiesIcon: {
    width: vw(45),
    height: vh(27.5),
  },

  containerBonus: {
    position: 'absolute',
    top: vh(71),
    right: vw(3),
  },

  containerImageBonusText: {
  
    marginBottom: -vh(1),
    marginLeft: vw(5),
    // migue
  },

  imageBonusText: {
    width: vw(28),
    height: vh(9),
  },

  containerImageBonusIcon: {
    marginRight: -vw(1.25),
    marginTop: -vh(3)
  },

  imageBonusIcon: {
    width: vw(45),
    height: vh(27.5),
  },

  textDoneButton: {
    textShadowOffset: {
      width: 0.25,
      height: 1,
    },
    textShadowRadius: 5,
  },
})
