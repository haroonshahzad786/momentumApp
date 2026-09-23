import { StyleSheet } from 'react-native'

import { vh, vw } from '../../helpers/dimensions'

export default StyleSheet.create({
  container: {
    flex: 1,
    // width: vw(52.5),
    marginBottom: vh(4),
  },

  containerTextTitle: {
    // marginBottom: vh(0.25),
  },

  containerImageSeparator: {
    marginVertical:vh(0.5)
  },

  imageSeparator: {
    width:'100%',
  },

  containerTextInputAnswer: {
  },

  separationHorizontal:{
    paddingHorizontal: vw(4),
  },

  textInputAnswer:{
    // backgroundColor:'red',
    height:vh(3),
    padding:0,
  },

  arrowSize:{
    
  }
})
