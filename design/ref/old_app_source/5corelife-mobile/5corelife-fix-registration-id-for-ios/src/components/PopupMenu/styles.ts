import { StyleSheet } from 'react-native'
import { vh, vw } from '../../helpers/dimensions'
import { RFValue } from 'react-native-responsive-fontsize'

export default StyleSheet.create({
  container: {
    flex: 1,
    //backgroundColor:'red'
  },
  bgBotton:{
    // backgroundColor:'blue',
    zIndex:2,
    // opacity:0.5,
  },
  popupOption: {
    // marginLeft: 5,
 
  },
  menu:{
    // backgroundColor:'green'
  },
  optionWrapper: {
      // height: 35,
      minWidth: vw(20),
      maxWidth: vw(90),
      alignItems: 'center',
      justifyContent:'center',
      flexDirection: 'row',
  },
  optionsContainer:{
    borderRadius:300,
    backgroundColor:'black',
    elevation: 5,
    padding: vh(2),
  },
  openBtn: {
    color: 'white',
    fontSize: 5,
    textAlign:'center',
  },
  anchorStyle:{
    backgroundColor: 'green',
  }
})
