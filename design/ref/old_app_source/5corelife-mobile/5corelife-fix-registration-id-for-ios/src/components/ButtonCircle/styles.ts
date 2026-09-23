import { StyleSheet } from 'react-native'

import { vh, vw } from '../../helpers/dimensions'

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

  containerText: {
    marginBottom: -vh(0.5)
  },

  containerFooterButton: {
    // backgroundColor:'green',
    alignItems: 'center',
    width: vw(20),
  },

  imageText: {
    width: vw(20),
    height: vh(5),
    top: vh(1),
    zIndex: 1,
    // backgroundColor:'purple'
  },

  imageButtonIcon: {
    width: vw(18),
    height: vw(18),
    borderWidth: 3,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 500,
    zIndex: 2
  },

  noActiveBtn: {
    backgroundColor: '#1f1f1f',
    borderColor: '#b2b3b3',
  },

  isActiveBtn: {
    backgroundColor: '#b2b3b3',
    borderColor: '#000',
  },

  imageIcon: {
    width: vh(6),
    height: vh(6),
    zIndex: 10,
    // marginTop: vh(.5),
    // backgroundColor:'pink'
  },
  imageIconShadow: {
    width: vh(6),
    height: vh(6),
    position: 'absolute',
    opacity: 0.3,
    zIndex: -1,
    // backgroundColor:'pink'
  },
  moveUp: {
    
    // marginBottom: vh(1)
  },
  imageIconLock: {
    width: vw(12),
    height: vw(14),
    // backgroundColor:'pink'
  },

  iconBlocked: {
    position: 'absolute',
    opacity: 0.2,
    alignSelf: 'center',

    width: vw(10),
    height: vw(10),

    // backgroundColor: 'yellow',
  },

  infoBox: {
    width: vw(17),
    height: vh(3),
    position: 'absolute',
    bottom: -vh(1),
    borderRadius: 50,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    zIndex: 7
  },
  plusIcon: {
    width: vw(2),
    height: vh(2),
  },
  coinIcon: {
    width: vw(3),
    height: vh(2),
    // backgroundColor:'red',
  },

  textStyle: {
    marginHorizontal: vw(1),
  },

  activeStyle: {
    textShadowOffset: {
      width: 0,
      height: vh(0.5)
    },
    textShadowRadius: vh(1),
  },

  activeVeil: {
    width: vh(25),
    height: vh(25),
    position: 'absolute',
    borderRadius: 500,
    opacity: 0.6,
    zIndex: -5
  },

  touchable: {
    zIndex: 6,
  },

  wingsStyle: {
    position: 'absolute',
    // flex: 1,
  },

  statImage: {
    width: '100%',
    flexGrow: 1,
    flexBasis: 0,
    flexShrink: 0,
    // backgroundColor: 'purple',
  },
})
