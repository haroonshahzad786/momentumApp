import { StyleSheet } from 'react-native'

import { vh, vw } from '../../helpers/dimensions'

export default StyleSheet.create({

  headerDotsContainer: {
    marginTop: vh(1),
    // marginBottom: vh(2),
    height: vh(8),
    marginHorizontal: vw(5),
    flexDirection: 'row',
    alignItems: 'center',
    zIndex: 1
  },

  backButton: {
    flex: 1,
    alignItems: "flex-start",
  },

  backButtonHome: {
    width: '50%',
    height: vh(10),
    marginTop: vh(8),
    flexDirection: 'column',
    alignItems: "center",
    zIndex: 10
  },

  helpButton: {
    flex: 1,
    alignItems: "flex-end",
  },

  dotsContainer: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: "center",
    marginTop: vh(4),
  },

  dotsContainerWithout: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: "center"
  },

  dot: {
    marginRight: vw(1)
  },

  stylesCustomer: {
    transform: [{
      rotate: '90deg'
    }]
  },
})
