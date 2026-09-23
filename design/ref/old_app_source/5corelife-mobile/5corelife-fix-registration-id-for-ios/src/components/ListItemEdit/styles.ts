import { StyleSheet } from 'react-native'
import { vw } from '../../helpers/dimensions'

export default StyleSheet.create({
  viewContainer: {
    //
  },

  textNumber: {
  },

  textInputName: {
  },

  touchableOpacityImageRight: {
    alignSelf: 'flex-end'
  },

  viewImageLine: {
    alignSelf: 'center',
  },

  lineContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    marginHorizontal: vw(1)
  },

  lineNumber: {
    //backgroundColor: "red",
    flex: 1,
    alignItems: "flex-start",
  },
  lineText: {
    //backgroundColor: "yellow",
    flex: 8,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: "flex-start"
  },
  lineButton: {
    //backgroundColor: "blue",
    flex: 1,
    alignItems: "flex-end",
  }

})
