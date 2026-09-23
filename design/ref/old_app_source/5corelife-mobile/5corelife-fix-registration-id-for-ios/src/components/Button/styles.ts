import { StyleSheet } from 'react-native'

import { vh } from '../../helpers/dimensions'

export default StyleSheet.create({
  container: {
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#000000',
    shadowOffset: {
      width: 0,
      height: 5
    },
    shadowOpacity: 0.5,
    shadowRadius: 10,
    elevation: 5
  },

  /*containerText: {
    marginBottom: -vh(0.1)
  }*/
})
