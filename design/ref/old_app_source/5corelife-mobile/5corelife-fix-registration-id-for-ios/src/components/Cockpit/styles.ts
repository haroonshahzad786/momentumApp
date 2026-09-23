import { StyleSheet } from 'react-native'

import { vh, vw } from '../../helpers/dimensions'

export default StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#000000',
  },

  containerImageBackgroundCockpit: {
    width: vw(120),
    height: vh(107),
    marginLeft: -vw(10),
  },

  containerConsoleCenter:{
    position: 'absolute',
    top: -vh(2.6),
    left: vw(35),
    width: vw(50),
    height: vh(60)
  },
  contolerCenter:{
    width: '100%',
    height: '100%'
  },
  containerConsoleLeft:{
    position: 'absolute',
    top: '38%',
    left: vw(12),
    width: vw(20),
    height: vh(60)
  },
  contolerLeft:{
    width: '100%',
    height: '100%'
  },
  containerConsoleRight:{
    position: 'absolute',
    top: '24%',
    right: vw(6.5),
    width: vw(20),
    height: vh(60)
  },
  contolerRight:{
    width: '100%',
    height: '100%'
  },
})
