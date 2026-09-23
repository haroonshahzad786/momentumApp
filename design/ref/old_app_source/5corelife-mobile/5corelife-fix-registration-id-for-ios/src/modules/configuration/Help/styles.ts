import { StyleSheet } from 'react-native'
import { vh, vw } from '../../../helpers/dimensions'

export default StyleSheet.create({
  container: {
    flex: 1
  },

  containerChild: {
    flex: 1
  },

  containerButtonBack: {
    position: 'absolute',
    top: vh(5.5),
    left: vw(5)
  },

  containerHeaderSettings: {
    marginTop: vh(11),
    marginBottom: vh(2)
  },

  // imageBackgroundContainer: {
  //   flex: 1
  // },

  // viewButtonBack: {
  //   position: 'absolute',
  //   top: vh(5.5),
  //   left: vw(5)
  // },

  // viewHeaderSettings: {
  //   alignSelf: 'center',
  //   position: 'absolute',
  //   top: vh(11)
  // },

  // viewElements: {
  //   alignSelf: 'center',
  //   position: 'absolute',
  //   top: vh(22),
  //   paddingHorizontal: vw(10),
  //   width:'100%'
  // },

  // textTitle: {
  //   marginVertical: vh(3),
  //   textAlign: 'center',
  //   textShadowOffset: {
  //     width: 1,
  //     height: 1
  //   },
  //   textShadowRadius: 5,
  //   elevation: 5
  // },

  // textSubtitle: {
  //   textAlign: 'center',
  //   lineHeight: vh(5),
  //   textShadowOffset: {
  //     width: 1,
  //     height: 1
  //   },
  //   textShadowRadius: 5,
  //   elevation: 5
  // }
})
