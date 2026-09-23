import { StyleSheet } from 'react-native'

import { vh, vw } from '../../../helpers/dimensions'

export default StyleSheet.create({
  container: {
    flex: 1
  },

  containerSub: {
    flex: 1
  },

  containerButtonBack: {
    position: 'absolute',
    top: vh(5.5),
    left: vw(5)
  },

  containerHeaderSettings: {
    marginTop: vh(11)
  },

  containerCardQuest: {
    marginHorizontal: vw(7.5),
    marginTop: vh(1.5),
    paddingHorizontal: vw(5),
    paddingTop: vh(1.5),
    paddingBottom: vh(2.5),
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

  containerCardQuestTextHeader: {
    marginBottom: vh(1.5)
  },

  textQuestHeader: {
    textAlign: 'center',
    textTransform:'uppercase'
  },

  touchableOpacityImageIconEdit: {
    position: 'absolute',
    right: vw(0)
  },

  imageIconEdit: {
    width: vw(5)
  },

  containerCardQuestImageLine: {
    marginBottom: vh(1.75)
  },

  imageCardQuestLine: {
    width: vw(60),
    alignSelf: 'center'
  },

  viewUserDetails: {
    paddingHorizontal: vw(5)
  },

  viewUserDetail: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginTop: vh(0.5),
    marginBottom: -vh(1)
  },

  imageIconUserDetail: {
    width: vw(4.25)
  },

  viewButtonsSettings: {
    alignSelf: 'center',
    marginTop: vh(2.5)
  },

  viewButtonSettings: {
    //
  },

  buttonSettings: {
    width: vw(85),
    height: vh(7.5),
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

  // ----- v

  containerCardQuestTextTitle: {
    marginBottom: vh(0.75)
  },

  textQuestTitle: {
    // textAlign: 'center'
  },

  containerCardQuestTextDescription: {
    //
  },

  textQuestDescription: {
    textAlign: 'center'
  },

  containerImprovements: {
    position: 'absolute',
    top: vh(46.5),
    left: vw(22.5)
  },

  containerImageImprovementsText: {
    marginBottom: -vh(5.5)
  },

  imageImprovementsText: {
    width: vw(55)
  },

  containerImageImprovementsIcon: {
    marginLeft: -vw(1)
  },

  imageImprovementsIcon: {
    width: vw(75),
    height: vh(37.5)
  },

  containerTrophies: {
    position: 'absolute',
    top: vh(75),
    left: vw(7.5)
  },

  containerImageTrophiesText: {
    marginBottom: -vh(3)
  },

  imageTrophiesText: {
    width: vw(35)
  },

  containerImageTrophiesIcon: {
    marginLeft: -vw(1.25)
  },

  imageTrophiesIcon: {
    width: vw(45),
    height: vh(27.5)
  },

  containerBonus: {
    position: 'absolute',
    top: vh(75),
    right: vw(3)
  },

  containerImageBonusText: {
    marginBottom: -vh(3),
    marginLeft: vw(5)
  },

  imageBonusText: {
    width: vw(28)
  },

  containerImageBonusIcon: {
    marginRight: -vw(1.25)
  },

  imageBonusIcon: {
    width: vw(45),
    height: vh(27.5)
  },

  buttonSettingsLogout: {
    width: vw(40),
    height: vh(5.5),
    paddingHorizontal: vw(2),
    borderRadius: 40,
  },

  animatedViewScreen: {
    alignSelf: 'center',
    position: 'absolute',
    bottom: vh(125),
    zIndex:3
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
    textAlignVertical: 'center'
  },

  buttons: {
    width: vw(10),
    height: vh(6)
  }
})
