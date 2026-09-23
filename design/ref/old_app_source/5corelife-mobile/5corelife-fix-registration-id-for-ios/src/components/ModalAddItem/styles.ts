import { StyleSheet } from 'react-native'

import { vh, vw } from '../../helpers/dimensions'

export default StyleSheet.create({

  imageBackgroundContainer: {
    //backgroundColor: '#000000AA',
    //width: vw(100),
    height: vh(61),
    position: 'absolute', 
    left: 0, 
    right: 0, 
    bottom: 0, 
    top: -vh(5),
  },

  textTitle: {
    //backgroundColor: '#ff00ffAA',
    //alignSelf: 'center',
    width: vw(50),
    marginTop: vh(20.5),
    textAlign: 'center',
    fontSize: vw(4)
  },
  lineText: {
    flex: 1,
    // backgroundColor: '#f600ffAA',
    marginTop: -vh(3),
    marginHorizontal: vw(13),
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: "flex-start"
  },
  textInputName: {
    flex: 1,
  },
  containerText: {
    //backgroundColor: '#f600ffAA',
    flexBasis: '70%',
    alignItems: 'center',
  },
  containerButtons: {
    //backgroundColor: '#2200ffAA',
    //flexDirection: 'column',
    flexBasis: '32%',
    flexDirection: 'row',
    alignItems: 'center'
  },

  cancelButton: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-around'
  },

  okButton: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-around'
  },
})
