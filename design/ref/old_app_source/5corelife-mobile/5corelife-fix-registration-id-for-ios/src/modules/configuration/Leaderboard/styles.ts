import { StyleSheet } from 'react-native'
import { vh, vw } from '../../../helpers/dimensions'
import { RFValue } from 'react-native-responsive-fontsize'

export default StyleSheet.create({
  container: {
    flex: 1,
  },

  containerSub: {
    flex: 1,
    height:'100%',
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
    flexDirection:'row',
    alignItems:'center',
    justifyContent:'center',
    position:'relative'
  },

  
  containerCardQuest: {
    marginHorizontal: vw(7.5),
    marginTop: vh(1.5),
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
    elevation: 5,
    // backgroundColor:'yellow'
  },

  containerCardQuestTextHeader: {
    marginBottom: vh(0.5),
    paddingBottom:  vh(1),
    borderBottomWidth: 0.5,
    flexDirection:'row',
    justifyContent:'space-between',
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
  containerScoreRow:{
    flexDirection:'row',
    alignItems:'center',
  },
  containerRows: {
     height: vh(70),
     marginLeft:-vw(5),
    //  backgroundColor:'red'
  },
  containerImageImprovementsIcon: {
    // backgroundColor:'green',
  },
  imageImprovementsIcon: {
    width: vw(15),
    minHeight: vw(15),
    // backgroundColor:'green',
    justifyContent:'center',
    alignItems:'center',
  },
  containerBackCard:{
  },
  rowText:{
    flexDirection:'row',
    width:'60%',
    // flexBasis:'60%'
  },
  rocketIcon:{
    // backgroundColor:'red',
    width: vh(5),
    height: vh(5),
    transform: [{
      rotate: '45deg'
    }]
  },
  arrowRight:{
    width: vw(4),
    height: vw(6),
  },
  userListHeader:{
    // backgroundColor:'blue',
  },
})
