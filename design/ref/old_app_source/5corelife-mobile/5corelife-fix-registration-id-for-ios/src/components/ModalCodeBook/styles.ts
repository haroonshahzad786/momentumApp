import { StyleSheet } from 'react-native'

import { vh, vw } from '../../helpers/dimensions'

export default StyleSheet.create({

  imageBackgroundContainer: {
    //backgroundColor: '#000000AA',
    //width: vw(140),
    width: vw(90),
    height: vh(100),
    alignSelf: 'center',
    marginTop: -vh(30),
  },

  textTitle: {
    //backgroundColor: '#ff00ffAA',
    //alignSelf: 'center',
    alignSelf: 'center',
    marginTop: vh(38.2)
  },
  containerText: {
    //backgroundColor: '#f600ffAA',
    flexBasis: '70%',
    alignItems: 'center',
  },
  containerButtons: {
    //backgroundColor: '#2200ffAA',
    flexDirection: 'row',
    flexBasis: '23%',
    alignItems: 'center',
  },

  cancelButton: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-around'
  },

  okButton: {
    /* flex: 1,
     flexDirection: 'row',
     alignItems: 'center',
     justifyContent: 'flex-end',
     marginRight: vh(10)*/
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-around'
  },

  containerTextLine: {
    marginTop: -vh(3),
    alignSelf: 'center',
  },

  textInput: {
    marginTop: vh(7),
    position: 'absolute',
    alignSelf: 'center',
    width: vw(70),
    height: vh(5),
    paddingBottom: 0,
    letterSpacing: vw(5.9),
    fontSize: vw(8),
  },

  containerImage:{
    // marginTop: -vh(5),
  },

  containerLine: {
    marginTop: -vh(3),
    flexDirection: 'row',
  },

  styleLine: {
    width: vw(32),
    height: vh(30)
  },

  spaceLine: {
    marginRight: 10
  },

  codeQR: {
    position: 'absolute',
    flex: 1,
    width: vw(16),
    height: vh(6.5),
    alignSelf: 'center',
    marginTop: -vh(10),
  },
})
