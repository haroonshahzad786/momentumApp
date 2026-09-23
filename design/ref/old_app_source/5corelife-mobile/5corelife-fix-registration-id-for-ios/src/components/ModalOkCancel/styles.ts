import { StyleSheet } from 'react-native'

import { vh, vw } from '../../helpers/dimensions'

export default StyleSheet.create({

  imageBackgroundContainer: {
    //backgroundColor: '#000000AA',
    //width: vw(100),
    height: vh(60),
    marginTop: -vh(45)
  },

  textTitle: {
    //backgroundColor: '#ff00ffAA',
    //alignSelf: 'center',
    width: vw(50),
    marginTop: vh(25),
    textAlign: 'center'
  },
  containerText: {
    //backgroundColor: '#f600ffAA',
    flexBasis: '70%',
    alignItems: 'center',
  },
  containerButtons: {
    //backgroundColor: '#2200ffAA',
    //flexDirection: 'column',
    flexBasis: '30%',
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
