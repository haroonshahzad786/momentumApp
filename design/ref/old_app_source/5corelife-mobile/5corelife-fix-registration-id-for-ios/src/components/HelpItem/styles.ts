import { StyleSheet } from 'react-native'

import { vh, vw } from '../../helpers/dimensions'

export default StyleSheet.create({
  container: {
    marginHorizontal: vw(2),
  },
  row: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    height: 56,
    paddingLeft: 25,
    paddingRight: 18,
    alignItems: 'center',
  },
  parentHr: {
    borderBottomColor: 'rgba(0, 0, 0, .5)',
    borderBottomWidth: 1,
    marginHorizontal: vw(4),
  },
  child: {
    padding: 16,
  },
  textTitle: {
    //marginVertical: vh(2),
    textAlign: 'left',
    textShadowOffset: {
      width: 1,
      height: 1
    },
    textShadowRadius: 5,
    elevation: 5
  },
  textSubtitle: {
    marginLeft: vw(8),
    textAlign: 'left',
    lineHeight: vh(5),
  },
  textDescription: {
    marginLeft: vw(8),
    marginBottom: 20,
    textAlign: 'left',
    lineHeight: vh(5),
  },
  imageLine: {
    alignSelf: 'flex-start',
    marginVertical: 10
  },
  textSeparator: {
    marginLeft: vw(8),
    marginBottom: 20,
    textAlign: 'center',
    lineHeight: vh(5),
  },
})
