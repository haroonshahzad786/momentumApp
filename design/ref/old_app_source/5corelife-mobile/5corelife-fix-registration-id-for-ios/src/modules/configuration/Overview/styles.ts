import { StyleSheet } from 'react-native'
import { vh, vw } from '../../../helpers/dimensions'
import { RFValue } from 'react-native-responsive-fontsize'

export default StyleSheet.create({
  container: {
    flex: 1,
  },

  containerSub: {
    flex: 1,
    height: '100%'
  },

  containerButtonBack: {
    position: 'absolute',
    top: vh(5.5),
    left: vw(5),
    zIndex: 9
  },
  containerButtonNext: {
    position: 'absolute',
    left: vw(6),
    transform: [{ rotate: '180deg' }]
  },
  containerHeaderSettings: {
    marginTop: vh(11),
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    position: 'relative'
  },
  containerBackCard: {
  },
  containerCardQuest: {
    marginHorizontal: vw(7.5),
    marginTop: vh(1.5),
    borderRadius: 40,
    borderWidth: 3,
    shadowColor: '#000000',
    shadowOffset: {
      width: 20,
      height: 20
    },
    shadowOpacity: 0.75,
    shadowRadius: 12.5,
    elevation: 5,
  },
  containerRows: {
    borderRadius: 40,
    marginTop: vh(2.5),
  },
  containerScoreRow: {
    // backgroundColor:'red',
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: vh(2.5),
  },
  containerImageImprovementsIcon: {
  },
  imageImprovementsIcon: {
    width: vw(15),
    marginLeft: '-5%',
    minHeight: vw(15),
  },
  rowText: {
    flexDirection: 'row',
  },
  rowContainerData: {
    flexDirection: 'row',
    paddingLeft: vw(8),
    width: '100%',
    alignItems: 'center',
    height: vw(10),
  },
  rowBackground: {
    paddingLeft: vw(8),
    width: '100%',
    height: vw(10),
  },
  offsetContainerIcon: {
    position: 'absolute',
    marginLeft: "-5%",
    zIndex: 9
  },
  containerBubble: {
    width: vw(12),
    height: vw(12),
    borderRadius: 500,
    borderWidth: 3,
    overflow: 'hidden',
    shadowColor: '#000000',
    elevation: 5,
  },
  iconBubble: {
    width: vw(8),
    height: vw(8),
    marginTop: '15%',
    marginLeft: '10%',
  },
  bgRowCollapse: {
    width: vw(15),
    marginLeft: '-5%',
    minHeight: vw(15),
    position: 'absolute',
  },
  butExpand: {
    width: vw(3),
    height: vw(2.2),
    marginLeft: 'auto',
    marginRight: "5%",
    // transform: [{ rotate: '180deg' }]
  },
  collapseDataContainer: {
    padding: '5%'
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
