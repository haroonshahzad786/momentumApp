import { StyleSheet } from 'react-native'
import { RFValue } from 'react-native-responsive-fontsize'

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
    left: vw(5),
    zIndex: 2
  },

  containerHeaderSettings: {
    marginTop: vh(5),
  },

  containerCardQuest: {
    marginHorizontal: vw(7.5),
    marginTop: vh(1.5),
    paddingHorizontal: vw(15),
    paddingTop: vh(1.5),
    paddingBottom: vh(2.5),
    borderRadius: 40,
    borderWidth: 3,
    textShadowOffset: {
      width: 0,
      height: vh(0.5)
    },
    textShadowRadius: vh(1),
  },

  containerCardQuestTextHeader: {
    marginBottom: vh(1.5)
  },

  textQuestHeader: {
    textAlign: 'center'
  },

  containerCardQuestImageLine: {
    marginBottom: vh(1.75)
  },

  imageCardQuestLine: {
    width: vw(60),
    alignSelf: 'center'
  },

  containerCardQuestTextTitle: {
    marginBottom: vh(0.75)
  },

  textQuestTitle: {
    textAlign: 'center'
  },

  containerCardQuestTextDescription: {
  },

  textQuestDescription: {
    textAlign: 'center',
    lineHeight: RFValue(24)
  },

  containerBgImprovementsIcon: {
  },

  containerImprovements: {
    justifyContent: 'center',
    alignContent: 'center'
  },

  containerImageImprovementsIcon: {
    height: vh(45),
    flexDirection: 'row',
    alignContent: 'center'
  },

  imageImprovementsIcon: {
    height: vh(43),
    width: vh(43),
    paddingTop: vh(5),
    overflow: 'hidden',
    justifyContent: 'center',
    alignItems: 'center'
  },

  imageRocket: {
    width: vh(30),
    height: vh(35),
    zIndex: 10
  },

  imageNewRocket: {
    width: vh(30),
    height: vh(35),
    zIndex: 10
  },

  alignBgFooter: {
    flexDirection: 'row',
    paddingHorizontal: vw(5),
    marginTop: vh(8),
    justifyContent: 'center',
    flexWrap: 'wrap',
    alignItems: 'flex-start',
    alignContent: 'flex-start',
    zIndex:-1,
  },

  buttonsBox: {
    flexDirection: 'row',
    justifyContent: 'center',
    flexWrap: 'wrap',
    alignItems: 'flex-start',
    alignContent: 'flex-start',
    marginTop: -vh(9),
  },

  alignBgWindow: {
    justifyContent: 'center',
  },

  containerButtonNormal: {
    marginHorizontal: vw(5),
    marginTop: vh(1),
  },

  imageBtnGreen: {
    width: vh(25),
    height: vh(18),
    alignItems: 'center',
    justifyContent: 'center',
  },

  touchableStyle: {
    position: 'absolute',
    bottom: -vh(5),
    width: vh(25),
    height: vh(18),
    alignItems: 'center',
    justifyContent: 'center',
  },

  fontButton: {
    marginBottom: vh(2)
  },

  styleCenterRocketActived: {
    width: vh(6),
    height: vh(6),
    zIndex: 10,
  },
  styleCenterBaseRocketActived: {
    marginTop: vh(2),
    flex: 1
  },
})
