import { StyleSheet } from 'react-native'

import { vh, vw } from '../../../helpers/dimensions'

export default StyleSheet.create({
  widgetContainer: {
    width: vw(21),
    height: vh(5),
    flexDirection: 'row',
    marginVertical: vh(1.2),
    borderRadius:500,
  },
  leftSide: {
    position: 'absolute',
    // backgroundColor: 'red',
    height: vh(8),
    left: -vw(1.5),
    top: -vh(1.2),
    width: vw(15),
  },
  rightSide: {
    paddingLeft: vw(1.5),
    // backgroundColor: 'green',
  },
  statBackground: {
    flexGrow: 1,
    flexBasis: 0,
  },
  statImage: {
    width: '100%',
    flexGrow: 1,
    flexBasis: 0,
    flexShrink: 0,
    // backgroundColor: 'purple',
  },
  statText: {
    position: 'absolute',
    left: vw(15),
    top: vh(1.9),
  },
  statLockedIcon: {
    position: 'absolute',
    left: vw(15),
    top: vh(2),
    width: vw(4.5),
    height: vh(3),
    // backgroundColor: 'red',
  },
  rightSideBg:{
    // backgroundColor: 'red',
    position:'absolute'
  }
})
