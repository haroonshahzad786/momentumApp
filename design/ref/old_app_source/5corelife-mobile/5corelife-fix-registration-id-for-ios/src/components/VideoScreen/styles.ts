import { StyleSheet } from 'react-native'
import { vh, vw } from '../../helpers/dimensions'
import { RFValue } from 'react-native-responsive-fontsize'

export default StyleSheet.create({
  bgModal:{
    width:'100%',
    height:'100%',
    backgroundColor:'black',
    alignContent:'center',
    justifyContent:'center'
  },
  container: {
    flex: 1,
  },
  viewContainer: {
    backgroundColor:'black'
  },
  video:{
    marginTop:'auto',
    height:vh(130),
  },
  containerButtonNext: {
    position: 'absolute',
    bottom: vh(1),
    right: vw(1),
  },
  buttonNext: {
    width: vw(15),
    height: vh(10)
  },
  modalContainer:{
    height:vh(200),
    // marginLeft:'-1%',
    // marginLeft:'auto',
    // marginRight:'auto',
    // marginTop:'auto',
    // width:vw(100),
  }
})
