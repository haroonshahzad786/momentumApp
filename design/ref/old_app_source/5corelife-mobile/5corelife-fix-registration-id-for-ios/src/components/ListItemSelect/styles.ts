import { StyleSheet } from 'react-native'
import { vh, vw } from '../../helpers/dimensions'

export default StyleSheet.create({
  viewContainer: {
    width: vw(55),
    // backgroundColor: "yellow",
    alignItems: 'flex-start',
  },

  textNumber: {
  },
  marginTop:{
    marginTop: vh(1)
  },


  textInputName:{
    marginLeft: vw(3)
  },

  textInputOption: {
    marginRight: '-5%'
  },


  touchableOpacityImageRight: {
    // alignSelf: 'center'
    marginLeft: vw(3)
  },

  viewImageLine: {
    alignSelf: 'center',
  },

  lineContainer: {
    width: '70%',
    flexDirection: 'row',
    alignItems: 'flex-start',
    justifyContent: 'space-between',
    // backgroundColor: "yellow",
  },

  lineNumber: {
    //backgroundColor: "red",
    flex: 1,
    alignItems: "flex-start",
  },
  lineText: {
    // backgroundColor: "yellow",
    flex: 8,
    flexDirection: 'row',
    justifyContent: "space-between"
  },
  lineButton: {
    //backgroundColor: "blue",
    flex: 1,
    height: '100%',
    justifyContent: 'center',
    // alignItems: "center",
  },

  success: {
    backgroundColor: 'rgba(39, 174,	96, .3)'
  },
  failed: {
    backgroundColor: 'rgba(192	,57	,43 ,.3)'
  },

})
