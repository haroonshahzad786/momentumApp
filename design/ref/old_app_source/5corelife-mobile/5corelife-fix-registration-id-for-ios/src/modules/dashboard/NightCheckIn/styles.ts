import { StyleSheet } from 'react-native'
import { vh, vw } from '../../../helpers/dimensions'
import { RFValue } from 'react-native-responsive-fontsize'

export default StyleSheet.create({
  container: {
    flex: 1,
  },

  containerSub: {
    flex: 1,
    height: '100%',
    marginTop: vh(5)
  },

  containerButtonBack: {
    position: 'absolute',
    top: vh(5.5),
    left: vw(5),
    zIndex: 9
  },
  containerButtonNext: {
    position: 'absolute',
    right: vw(13),
  },
  containerHeaderSettings: {
    marginTop: vh(11),
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    position: 'relative'
  },


  containerCardQuest: {
    marginHorizontal: vw(7.5),
    marginTop: vh(1.5),
    paddingTop: vh(1.5),
    paddingBottom: vh(2.5),
    borderRadius: 20,
    borderWidth: 3,
    shadowColor: '#000000',
    shadowOffset: {
      width: 20,
      height: 20
    },
    shadowOpacity: 0.75,
    shadowRadius: 12.5,
    elevation: 5,
    // backgroundColor:'yellow'
  },

  containerCardQuestTextHeader: {
    marginBottom: vh(0.5),
    paddingBottom: vh(1),
    borderBottomWidth: 0.5,
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingHorizontal: vw(12),
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
    //
  },

  textQuestDescription: {
  },
  containerScoreRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  containerRows: {
    // flex: 1,
    height: vh(70),
    marginLeft: -vw(5),
    //  backgroundColor:'red'
  },
  containerImageImprovementsIcon: {
    // backgroundColor:'green',
  },
  imageImprovementsIcon: {
    width: vw(15),
    minHeight: vw(15),
    // backgroundColor:'green',
    justifyContent: 'center',
    alignItems: 'center',
  },
  containerBackCard: {
    marginBottom: vh(1)
  },
  rowText: {
    flexDirection: 'row',
    width: '60%',
    // flexBasis:'60%'
  },
  rocketIcon: {
    // backgroundColor:'red',
    width: vh(4),
    height: vh(4),
  },
  arrowRight: {
    width: vw(4),
    height: vw(6),
  },
  userListHeader: {
    // backgroundColor:'blue',
  },

  touchableStyle: {
    position: 'absolute',
    alignItems: 'center',
    justifyContent: 'center',
    width: '100%',
    bottom: vh(1)
  },

  scrollContainer: {
    paddingBottom: vh(8)
  },

  tabBar: {
    flexDirection: 'row',
    marginVertical: vh(1),
    justifyContent: 'center',
  },
  tabItem: {
    alignItems: 'center',
    paddingHorizontal: vh(2),
    paddingVertical: vw(2),
    borderRadius: 50,
    marginHorizontal: vh(2),
  },
  containerAccordion: {
    marginBottom: vh(3.5),
  },
  okBtn: {
    width: vw(30),
    marginTop: vh(10)
    // top: '50%'
  },
  alien1: {
    marginTop: vh(16.5),
    height: vw(140),
  }
})
